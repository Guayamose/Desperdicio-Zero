module Menus
  class GenerateDailyMenuService
    PRIORITY_WINDOW_DAYS = 2
    MAX_LOTS = 20
    PROMPT_VERSION = "v3-nutrition-profile".freeze

    LOW_STOCK_THRESHOLDS = {
      "kg" => 1.5,
      "g" => 500.0,
      "l" => 1.5,
      "ml" => 500.0,
      "unit" => 8.0
    }.freeze

    ABUNDANT_STOCK_THRESHOLDS = {
      "kg" => 4.0,
      "g" => 1800.0,
      "l" => 4.0,
      "ml" => 1800.0,
      "unit" => 18.0
    }.freeze

    RELIGIOUS_RISK_PATTERNS = {
      "contains_pork" => /\b(cerdo|pork|jamon|bacon|tocino|chorizo|salchichon|lardo|manteca)\b/i,
      "contains_alcohol" => /\b(alcohol|vino|beer|cerveza|ron|rum|whisky|licor|brandy)\b/i,
      "contains_ambiguous_gelatin" => /\b(gelatina|gelatin|emulsificante|e\-441)\b/i,
      "contains_ambiguous_enzymes" => /\b(cuajo|rennet|enzima|mono\s*y\s*digliceridos)\b/i
    }.freeze

    NUTRITION_CANDIDATE_KEYS = {
      "kcal_100g" => %w[energy-kcal_100g energy_kcal_100g],
      "protein_g_100g" => %w[proteins_100g protein_100g],
      "carbs_g_100g" => %w[carbohydrates_100g carbs_100g],
      "fat_g_100g" => %w[fat_100g fats_100g],
      "fiber_g_100g" => %w[fiber_100g fibres_100g],
      "salt_g_100g" => %w[salt_100g sodium_100g]
    }.freeze

    def initialize(tenant:, user:, ai_client: Integrations::OpenAiClient.new)
      @tenant = tenant
      @user = user
      @ai_client = ai_client
    end

    def call(date: Date.current, selected_lot_ids: nil)
      lots = selected_lots(selected_lot_ids)
      ingredients = self.class.ingredients_for(lots)
      planning_context = self.class.planning_context_for(lots)

      generation = MenuGeneration.create!(
        tenant: @tenant,
        requested_by: @user,
        input_lot_ids_json: lots.map(&:id),
        model: @ai_client.model,
        prompt_version: PROMPT_VERSION,
        status: :running
      )

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        ai_result = @ai_client.generate_menu(
          ingredients: ingredients,
          planning_context: planning_context,
          locale: @user&.locale || "es"
        )
        menu = upsert_menu_from_ai(ai_result, date)

        generation.update!(
          status: :succeeded,
          latency_ms: duration_ms(started_at),
          raw_response_encrypted: ai_result.to_json
        )

        AuditLogger.log!(
          action: "menu.generated",
          actor: @user,
          tenant: @tenant,
          entity: menu,
          metadata: { source: "ai", generation_id: generation.id, prompt_version: PROMPT_VERSION }
        )

        menu
      rescue StandardError => e
        menu = fallback_menu(date)

        generation.update!(
          status: :fallback_manual,
          latency_ms: duration_ms(started_at),
          error_code: e.class.name
        )

        AuditLogger.log!(
          action: "menu.fallback",
          actor: @user,
          tenant: @tenant,
          entity: menu,
          metadata: { reason: e.message }
        )

        menu
      end
    end

    private

    def prioritized_inventory_lots
      self.class.prioritized_lots_for(@tenant)
    end

    def selected_lots(selected_lot_ids)
      ids = Array(selected_lot_ids).map(&:to_i).uniq
      return prioritized_inventory_lots if ids.empty?

      lots = @tenant.inventory_lots.available.includes(:product).where(id: ids).order(expires_on: :asc).to_a
      lots.presence || prioritized_inventory_lots
    end

    class << self
      def prioritized_lots_for(tenant)
        available = tenant.inventory_lots.available.includes(:product).order(expires_on: :asc).limit(50).to_a
        critical, normal = available.partition { |lot| lot.expires_on <= Date.current + PRIORITY_WINDOW_DAYS.days }
        (critical + normal).first(MAX_LOTS)
      end

      def ingredients_for(lots)
        Array(lots).map { |lot| ingredient_payload(lot) }
      end

      def planning_context_for(lots)
        prepared_lots = Array(lots)
        grouped_products = summarize_products(prepared_lots)
        suggested_mode = suggest_production_mode(prepared_lots, grouped_products)

        {
          generatedAt: Time.current.iso8601,
          lotCount: prepared_lots.size,
          uniqueIngredients: grouped_products.size,
          urgentLots: prepared_lots.count { |lot| lot.expires_on <= Date.current + 1.day },
          highPriorityLots: prepared_lots.count { |lot| lot.expires_on <= Date.current + PRIORITY_WINDOW_DAYS.days },
          lowStockLots: prepared_lots.count { |lot| low_stock?(lot) },
          abundantLots: prepared_lots.count { |lot| abundant_stock?(lot) },
          quantityByUnit: quantity_by_unit(prepared_lots),
          topIngredients: grouped_products.first(8),
          suggestedMode: suggested_mode,
          menuGuideline: menu_guideline_for(suggested_mode)
        }
      end

      private

      def ingredient_payload(lot)
        product = lot.product

        {
          lotId: lot.id,
          product: product.name,
          brand: product.brand,
          category: product.category,
          knownAllergens: Array(product.allergens_json),
          knownNutrition: nutrition_hints_for(product.nutrition_json),
          religiousRiskHints: religious_risk_hints(product),
          ingredientsText: product.ingredients_text.to_s.truncate(180),
          quantity: lot.quantity.to_f,
          unit: lot.unit,
          expiresOn: lot.expires_on.iso8601,
          expiryPriority: expiry_priority_for(lot.expires_on)
        }
      end

      def nutrition_hints_for(raw_nutrition)
        return {} unless raw_nutrition.is_a?(Hash)

        NUTRITION_CANDIDATE_KEYS.each_with_object({}) do |(target_key, candidates), extracted|
          value = candidates.lazy.map { |source_key| raw_nutrition[source_key] }.find(&:present?)
          numeric = Float(value)
          extracted[target_key] = numeric.round(2)
        rescue StandardError
          nil
        end
      end

      def religious_risk_hints(product)
        searchable_text = [ product.name, product.category, product.ingredients_text ].compact.join(" ")

        RELIGIOUS_RISK_PATTERNS.each_with_object([]) do |(label, pattern), risks|
          risks << label if searchable_text.match?(pattern)
        end
      end

      def expiry_priority_for(expires_on)
        days_to_expiry = (expires_on - Date.current).to_i
        return "critical" if days_to_expiry <= 1
        return "high" if days_to_expiry <= PRIORITY_WINDOW_DAYS

        "normal"
      end

      def summarize_products(lots)
        lots.group_by { |lot| lot.product.name.to_s.downcase.strip }
            .values
            .map do |grouped_lots|
              reference = grouped_lots.first
              {
                product: reference.product.name,
                quantityByUnit: quantity_by_unit(grouped_lots),
                lotCount: grouped_lots.size,
                urgentLots: grouped_lots.count { |lot| lot.expires_on <= Date.current + 1.day },
                knownAllergens: Array(reference.product.allergens_json)
              }
            end
            .sort_by { |item| [ -item[:urgentLots], -item[:lotCount] ] }
      end

      def quantity_by_unit(lots)
        lots.each_with_object(Hash.new(0.0)) do |lot, totals|
          totals[lot.unit] += lot.quantity.to_f
        end.transform_values { |value| value.round(2) }
      end

      def suggest_production_mode(lots, grouped_products)
        return "balanced" if lots.empty?

        low_stock_ratio = lots.size.positive? ? lots.count { |lot| low_stock?(lot) }.to_f / lots.size : 0.0
        abundant_ratio = lots.size.positive? ? lots.count { |lot| abundant_stock?(lot) }.to_f / lots.size : 0.0

        if grouped_products.size >= 7 && low_stock_ratio >= 0.45
          "variety"
        elsif grouped_products.size <= 4 && abundant_ratio >= 0.4
          "batch"
        else
          "balanced"
        end
      end

      def menu_guideline_for(mode)
        case mode
        when "variety"
          "Inventario diverso y fragmentado: conviene crear mas platos distintos con porciones moderadas."
        when "batch"
          "Inventario concentrado y abundante: conviene pocos platos base con mas repeticiones/raciones."
        else
          "Inventario intermedio: combinar variedad moderada con algun plato repetible."
        end
      end

      def low_stock?(lot)
        threshold = LOW_STOCK_THRESHOLDS.fetch(lot.unit.to_s, 1.0)
        lot.quantity.to_f <= threshold
      end

      def abundant_stock?(lot)
        threshold = ABUNDANT_STOCK_THRESHOLDS.fetch(lot.unit.to_s, 3.0)
        lot.quantity.to_f >= threshold
      end
    end

    def upsert_menu_from_ai(ai_result, date)
      menu = @tenant.daily_menus.find_or_initialize_by(menu_date: date)
      menu.assign_attributes(
        title: ai_result["title"].presence || "Menu del dia",
        description: ai_result["description"],
        allergens_json: Array(ai_result["allergens"]),
        nutrition_summary_json: normalize_hash(ai_result["nutritionSummary"]),
        dietary_guidance_json: normalize_hash(ai_result["dietaryGuidance"]),
        planning_notes_json: normalize_hash(ai_result["planningNotes"]),
        status: :draft,
        generated_by: :ai,
        created_by: @user
      )
      menu.save!

      menu.daily_menu_items.destroy_all
      Array(ai_result["items"]).each_with_index do |item, index|
        menu.daily_menu_items.create!(
          position: index,
          name: item["name"].presence || "Plato #{index + 1}",
          description: compose_item_description(item),
          ingredients_json: Array(item["ingredients"]),
          allergens_json: Array(item["allergens"]),
          servings: normalized_integer(item["servings"], default: 1),
          repetitions: normalized_integer(item["repetitions"], default: 1),
          nutrition_json: normalize_hash(item["nutrition"]),
          dietary_flags_json: normalize_dietary_flags(item),
          religious_notes: item["religiousNotes"].to_s.strip,
          inventory_usage_json: normalize_inventory_usage(item["inventoryUsage"])
        )
      end

      menu
    end

    def fallback_menu(date)
      @tenant.daily_menus.find_or_initialize_by(menu_date: date).tap do |menu|
        menu.assign_attributes(
          title: "Menu pendiente de confirmacion",
          description: "No se pudo generar con IA. Edita manualmente este borrador y confirma cuando este listo.",
          status: :draft,
          generated_by: :manual,
          created_by: @user,
          nutrition_summary_json: {},
          dietary_guidance_json: {},
          planning_notes_json: {}
        )
        menu.save!
      end
    end

    def normalized_integer(raw_value, default:)
      numeric = Integer(raw_value)
      numeric.positive? ? numeric : default
    rescue ArgumentError, TypeError
      default
    end

    def normalize_hash(raw_value)
      return {} unless raw_value.is_a?(Hash)

      raw_value.deep_stringify_keys
    end

    def normalize_inventory_usage(raw_value)
      entries = raw_value.is_a?(Hash) ? raw_value.values : Array(raw_value)

      entries.map do |entry|
        usage = entry.is_a?(Hash) ? entry.deep_stringify_keys : {}
        normalized = {
          "lotId" => usage["lotId"].presence || usage["lot_id"],
          "product" => usage["product"].to_s.strip,
          "quantity" => usage["quantity"],
          "unit" => usage["unit"].to_s.strip
        }.compact

        normalized if normalized["lotId"].present? || normalized["product"].present?
      end.compact
    end

    def compose_item_description(item)
      base = item["description"].to_s.strip
      nutrition_rationale = item["nutritionRationale"].to_s.strip
      vegetarian_adaptation = item["vegetarianAdaptation"].to_s.strip

      sections = []
      sections << base if base.present?
      sections << "Justificacion nutricional: #{nutrition_rationale}" if nutrition_rationale.present?
      sections << "Adaptacion vegetariana: #{vegetarian_adaptation}" if vegetarian_adaptation.present?

      sections.join("\n")
    end

    def normalize_dietary_flags(item)
      flags = Array(item["dietaryFlags"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq
      vegetarian_adaptation = item["vegetarianAdaptation"].to_s.strip
      flags << "vegetarian_adaptation_available" if vegetarian_adaptation.present?
      flags.uniq
    end

    def duration_ms(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).to_i
    end
  end
end
