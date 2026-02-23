module Menus
  class GenerateDailyMenuService
    PRIORITY_WINDOW_DAYS = 2
    MAX_LOTS = 20

    def initialize(tenant:, user:, ai_client: Integrations::OpenAiClient.new)
      @tenant = tenant
      @user = user
      @ai_client = ai_client
    end

    def call(date: Date.current, selected_lot_ids: nil)
      lots = selected_lots(selected_lot_ids)
      ingredients = self.class.ingredients_for(lots)

      generation = MenuGeneration.create!(
        tenant: @tenant,
        requested_by: @user,
        input_lot_ids_json: lots.map(&:id),
        model: @ai_client.model,
        prompt_version: "v1",
        status: :running
      )

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        ai_result = @ai_client.generate_menu(ingredients: ingredients, locale: @user&.locale || "es")
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
          metadata: { source: "ai", generation_id: generation.id }
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

      private

      def ingredient_payload(lot)
        {
          lotId: lot.id,
          product: lot.product.name,
          brand: lot.product.brand,
          category: lot.product.category,
          knownAllergens: Array(lot.product.allergens_json),
          quantity: lot.quantity.to_f,
          unit: lot.unit,
          expiresOn: lot.expires_on.iso8601
        }
      end
    end

    def upsert_menu_from_ai(ai_result, date)
      menu = @tenant.daily_menus.find_or_initialize_by(menu_date: date)
      menu.assign_attributes(
        title: ai_result["title"].presence || "Menu del dia",
        description: ai_result["description"],
        allergens_json: Array(ai_result["allergens"]),
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
          description: item["description"],
          ingredients_json: Array(item["ingredients"]),
          allergens_json: Array(item["allergens"])
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
          created_by: @user
        )
        menu.save!
      end
    end

    def duration_ms(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).to_i
    end

  end
end
