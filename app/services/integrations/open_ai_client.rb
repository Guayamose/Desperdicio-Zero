module Integrations
  class OpenAiClient
    BASE_URL = "https://api.openai.com".freeze
    VALID_HALAL_STATUSES = %w[compatible needs_review not_compatible].freeze
    VALID_PRODUCTION_MODES = %w[variety batch balanced].freeze

    SYSTEM_PROMPT = <<~PROMPT.freeze
      Eres chef ejecutivo y nutricionista de un comedor social con foco en desperdicio cero.
      Contexto poblacional prioritario:
      - Usuarios mayoritariamente adultos de 30 a 64 anos en situacion de vulnerabilidad social.
      - Distribucion de referencia: 76% hombres y 24% mujeres.
      - Alta probabilidad de malnutricion previa, hipertension, diabetes tipo 2 y bajo consumo proteico historico.
      Devuelve exclusivamente JSON valido (sin markdown, sin texto adicional) con esta estructura exacta:
      {
        "title": "string",
        "description": "string",
        "allergens": ["string"],
        "nutritionSummary": {
          "estimatedTotalKcal": 0,
          "estimatedAverageKcalPerServing": 0,
          "proteinFocus": "string",
          "carbFocus": "string",
          "fatFocus": "string",
          "notes": "string"
        },
        "dietaryGuidance": {
          "halalStatus": "compatible|needs_review|not_compatible",
          "haramRisks": ["string"],
          "vegetarianOptions": ["string"],
          "veganOptions": ["string"],
          "religiousNotes": "string"
        },
        "planningNotes": {
          "productionMode": "variety|batch|balanced",
          "strategy": "string",
          "estimatedTotalServings": 0,
          "wasteReductionPlan": ["string"]
        },
        "items": [
          {
            "name": "string",
            "description": "string",
            "ingredients": ["ingrediente + cantidad por racion (ej: lentejas cocidas 180 g por racion)"],
            "allergens": ["string"],
            "servings": 0,
            "repetitions": 0,
            "nutrition": {
              "kcal": 0,
              "protein_g": 0,
              "carbs_g": 0,
              "fat_g": 0,
              "fiber_g": 0,
              "salt_g": 0
            },
            "nutritionRationale": "string",
            "vegetarianAdaptation": "string",
            "dietaryFlags": ["string"],
            "religiousNotes": "string",
            "inventoryUsage": [
              {
                "lotId": 0,
                "product": "string",
                "quantity": 0,
                "unit": "kg|g|l|ml|unit"
              }
            ]
          }
        ]
      }

      Reglas de negocio:
      - Usa al maximo los lotes con caducidad mas cercana.
      - Ajusta el numero de platos segun inventario y modo recomendado:
        - productionMode=variety: mas platos distintos y porciones moderadas.
        - productionMode=batch: menos platos, mas repeticiones/raciones.
        - productionMode=balanced: punto intermedio.
      - Calcula servings y repetitions coherentes con cantidades disponibles.
      - Cada plato debe incluir nombre claro y preparacion sencilla para personal no tecnico.
      - Cada plato debe cumplir SIEMPRE:
        - kcal entre 700 y 900 por racion.
        - protein_g entre 25 y 35 por racion.
        - salt_g menor de 2 por racion.
      - Prioriza densidad nutricional con foco en hierro, fibra y vitaminas del grupo B.
      - Minimiza ingredientes ultraprocesados y evita depender de ellos.
      - Prioriza alimentos basicos habituales en bancos de alimentos en Espana cuando esten disponibles:
        legumbres, arroz, pasta, patata, verduras de temporada, pollo, huevos y pescado en conserva.
      - En ingredients indica cantidades por racion de forma explicita y util para cocina.
      - Incluye nutritionRationale por plato, explicando por que cubre necesidades del perfil objetivo.
      - Incluye vegetarianAdaptation por plato con sustituciones concretas cuando sea viable.
      - Si hay riesgos halal/haram, declaralos claramente en haramRisks y religiousNotes.
      - Si no hay certeza total de halal, usa halalStatus=needs_review.
      - Incluye alergenos detectables y nunca omitas los obvios.
      - Proporciona estimaciones nutricionales realistas y redondeadas.
      - En inventoryUsage usa lotId cuando sea posible para trazabilidad.
      - Lenguaje claro para personal no tecnico.
      - Consumir menos del 10 % de calorías/día de azúcares añadidos.
    PROMPT

    attr_reader :model

    def initialize(connection: nil, api_key: ENV["OPENAI_API_KEY"], model: ENV.fetch("OPENAI_MODEL", "gpt-4o-mini"))
      @api_key = api_key
      @model = model
      @connection = connection || Faraday.new(url: BASE_URL) do |f|
        f.options.timeout = 30
        f.options.open_timeout = 30
        f.response :raise_error
        f.adapter Faraday.default_adapter
      end
    end

    def generate_menu(ingredients:, planning_context:, locale: "es")
      raise "OPENAI_API_KEY missing" if @api_key.blank?

      body = {
        model: @model,
        response_format: { type: "json_object" },
        temperature: 0.15,
        max_tokens: 1800,
        messages: [
          {
            role: "system",
            content: SYSTEM_PROMPT
          },
          {
            role: "user",
            content: {
              locale: locale,
              planningContext: planning_context,
              ingredients: ingredients
            }.to_json
          }
        ]
      }

      response = @connection.post("/v1/chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end

      payload = JSON.parse(response.body)
      content = payload.dig("choices", 0, "message", "content")
      content = content.map { |part| part.is_a?(Hash) ? part["text"] : part.to_s }.join("\n") if content.is_a?(Array)
      normalize_menu_payload(JSON.parse(content))
    rescue Faraday::Error, JSON::ParserError => e
      raise "openai_error: #{e.message}"
    end

    private

    def normalize_menu_payload(raw)
      title = raw["title"].to_s.strip
      description = raw["description"].to_s.strip
      planning_notes = normalize_planning_notes(raw["planningNotes"])
      items = normalize_items(raw["items"], planning_notes["productionMode"])

      raise "openai_error: empty_items" if items.empty?

      allergens = normalize_array(raw["allergens"])
      allergens = (allergens + items.flat_map { |item| item["allergens"] }).uniq

      nutrition_summary = normalize_nutrition_summary(raw["nutritionSummary"], items)
      dietary_guidance = normalize_dietary_guidance(raw["dietaryGuidance"], items)
      planning_notes["estimatedTotalServings"] ||= items.sum { |item| item["servings"].to_i * item["repetitions"].to_i }

      {
        "title" => title.presence || "Menu del dia",
        "description" => description,
        "allergens" => allergens,
        "nutritionSummary" => nutrition_summary,
        "dietaryGuidance" => dietary_guidance,
        "planningNotes" => planning_notes,
        "items" => items
      }
    end

    def normalize_items(raw_items, production_mode)
      items = Array(raw_items).map.with_index do |item, index|
        item_hash = item.is_a?(Hash) ? item : { "name" => item.to_s }

        {
          "name" => item_hash["name"].to_s.strip.presence || "Plato #{index + 1}",
          "description" => item_hash["description"].to_s.strip,
          "ingredients" => normalize_ingredients(item_hash["ingredients"]),
          "allergens" => normalize_array(item_hash["allergens"]),
          "servings" => normalize_positive_integer(item_hash["servings"], default: 1),
          "repetitions" => normalize_positive_integer(item_hash["repetitions"], default: 1),
          "nutrition" => normalize_item_nutrition(item_hash["nutrition"]),
          "nutritionRationale" => item_hash["nutritionRationale"].to_s.strip,
          "vegetarianAdaptation" => item_hash["vegetarianAdaptation"].to_s.strip,
          "dietaryFlags" => normalize_array(item_hash["dietaryFlags"]),
          "religiousNotes" => item_hash["religiousNotes"].to_s.strip,
          "inventoryUsage" => normalize_inventory_usage(item_hash["inventoryUsage"])
        }
      end.reject { |item| item["name"].blank? }

      max_items = case production_mode
                  when "variety" then 8
                  when "batch" then 4
                  else 6
                  end

      items.first(max_items)
    end

    def normalize_nutrition_summary(raw_summary, items)
      normalized = raw_summary.is_a?(Hash) ? raw_summary.deep_stringify_keys : {}

      total_servings = items.sum { |item| item["servings"].to_i * item["repetitions"].to_i }
      weighted_kcal = items.sum do |item|
        item["nutrition"]["kcal"].to_f * item["servings"].to_i * item["repetitions"].to_i
      end

      normalized["estimatedTotalKcal"] = normalize_number(normalized["estimatedTotalKcal"], default: weighted_kcal.nonzero?)
      normalized["estimatedAverageKcalPerServing"] = normalize_number(
        normalized["estimatedAverageKcalPerServing"],
        default: total_servings.positive? ? (weighted_kcal / total_servings) : nil
      )
      normalized["proteinFocus"] = normalized["proteinFocus"].to_s.strip
      normalized["carbFocus"] = normalized["carbFocus"].to_s.strip
      normalized["fatFocus"] = normalized["fatFocus"].to_s.strip
      normalized["notes"] = normalized["notes"].to_s.strip

      normalized.compact
    end

    def normalize_dietary_guidance(raw_guidance, items)
      normalized = raw_guidance.is_a?(Hash) ? raw_guidance.deep_stringify_keys : {}
      flags = items.flat_map { |item| item["dietaryFlags"] }.map(&:downcase).uniq

      halal_status = normalized["halalStatus"].to_s
      halal_status = "needs_review" unless VALID_HALAL_STATUSES.include?(halal_status)

      haram_risks = normalize_array(normalized["haramRisks"])
      if haram_risks.empty?
        haram_risks = infer_haram_risks_from_flags(flags)
      end

      {
        "halalStatus" => halal_status,
        "haramRisks" => haram_risks,
        "vegetarianOptions" => normalize_array(normalized["vegetarianOptions"]),
        "veganOptions" => normalize_array(normalized["veganOptions"]),
        "religiousNotes" => normalized["religiousNotes"].to_s.strip
      }
    end

    def normalize_planning_notes(raw_notes)
      normalized = raw_notes.is_a?(Hash) ? raw_notes.deep_stringify_keys : {}
      production_mode = normalized["productionMode"].to_s
      production_mode = "balanced" unless VALID_PRODUCTION_MODES.include?(production_mode)

      {
        "productionMode" => production_mode,
        "strategy" => normalized["strategy"].to_s.strip,
        "estimatedTotalServings" => normalize_positive_integer(normalized["estimatedTotalServings"], default: nil),
        "wasteReductionPlan" => normalize_array(normalized["wasteReductionPlan"])
      }.compact
    end

    def normalize_item_nutrition(raw_nutrition)
      nutrition = raw_nutrition.is_a?(Hash) ? raw_nutrition.deep_stringify_keys : {}

      normalized = {
        "kcal" => normalize_number(nutrition["kcal"] || nutrition["calories"]),
        "protein_g" => normalize_number(nutrition["protein_g"] || nutrition["protein"]),
        "carbs_g" => normalize_number(nutrition["carbs_g"] || nutrition["carbohydrates_g"] || nutrition["carbs"]),
        "fat_g" => normalize_number(nutrition["fat_g"] || nutrition["fat"]),
        "fiber_g" => normalize_number(nutrition["fiber_g"] || nutrition["fiber"]),
        "salt_g" => normalize_number(nutrition["salt_g"] || nutrition["salt"])
      }.compact

      normalized["kcal"] = clamp_number(normalized["kcal"], min: 700.0, max: 900.0, default: 800.0)
      normalized["protein_g"] = clamp_number(normalized["protein_g"], min: 25.0, max: 35.0, default: 30.0)
      normalized["salt_g"] = clamp_number(normalized["salt_g"], min: 0.0, max: 1.99, default: 1.5)

      normalized
    end

    def normalize_inventory_usage(raw_usage)
      entries = raw_usage.is_a?(Hash) ? raw_usage.values : Array(raw_usage)

      entries.map do |entry|
        usage = entry.is_a?(Hash) ? entry.deep_stringify_keys : {}

        normalized = {
          "lotId" => usage["lotId"].presence || usage["lot_id"],
          "product" => usage["product"].to_s.strip,
          "quantity" => normalize_number(usage["quantity"]),
          "unit" => usage["unit"].to_s.strip
        }.compact

        normalized if normalized["lotId"].present? || normalized["product"].present?
      end.compact
    end

    def infer_haram_risks_from_flags(flags)
      risks = []
      risks << "algunos platos marcan riesgo de haram" if flags.any? { |flag| flag.include?("haram") }
      risks
    end

    def normalize_positive_integer(value, default:)
      return default if value.nil?

      parsed = Integer(value)
      parsed.positive? ? parsed : default
    rescue ArgumentError, TypeError
      default
    end

    def normalize_number(value, default: nil)
      return default if value.nil?

      parsed = Float(value)
      parsed.round(2)
    rescue ArgumentError, TypeError
      default
    end

    def clamp_number(value, min:, max:, default:)
      numeric = normalize_number(value, default: default)
      return default if numeric.nil?

      [[ numeric, min ].max, max].min.round(2)
    end

    def normalize_ingredients(value)
      entries = value.is_a?(Hash) ? value.values : Array(value)

      entries.flat_map do |entry|
        if entry.is_a?(Hash)
          [ format_ingredient_entry(entry.deep_stringify_keys) ]
        else
          entry.to_s.split(",")
        end
      end.map(&:to_s).map(&:strip).reject(&:blank?).uniq
    end

    def format_ingredient_entry(entry)
      name = entry["name"].presence || entry["ingredient"].presence || entry["product"].presence
      quantity = entry["quantityPerServing"] || entry["quantity"] || entry["amount"]
      unit = entry["unit"].to_s.strip
      notes = entry["notes"].to_s.strip

      if name.present? && quantity.present?
        quantity_text = normalize_number(quantity, default: quantity).to_s
        unit_text = unit.presence || "unit"
        base = "#{name} #{quantity_text} #{unit_text} por racion"
        notes.present? ? "#{base} (#{notes})" : base
      else
        normalize_array(entry.values).join(" ")
      end
    end

    def normalize_array(value)
      Array(value)
        .flat_map { |entry| entry.to_s.split(",") }
        .map(&:strip)
        .reject(&:blank?)
        .uniq
    end
  end
end
