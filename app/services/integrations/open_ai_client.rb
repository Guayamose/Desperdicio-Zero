module Integrations
  class OpenAiClient
    BASE_URL = "https://api.openai.com".freeze
    SYSTEM_PROMPT = <<~PROMPT.freeze
      Eres chef y nutricionista de un comedor social.
      Devuelve exclusivamente JSON valido (sin markdown, sin texto adicional) con esta estructura:
      {
        "title": "string",
        "description": "string",
        "allergens": ["string"],
        "items": [
          {
            "name": "string",
            "description": "string",
            "ingredients": ["string"],
            "allergens": ["string"]
          }
        ]
      }
      Reglas:
      - Prioriza ingredientes con caducidad mas cercana.
      - Propone entre 2 y 4 platos.
      - Usa lenguaje claro para personal no tecnico.
      - Incluye alergenos detectables a partir de ingredientes.
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

    def generate_menu(ingredients:, locale: "es")
      raise "OPENAI_API_KEY missing" if @api_key.blank?

      body = {
        model: @model,
        response_format: { type: "json_object" },
        temperature: 0.2,
        max_tokens: 900,
        messages: [
          {
            role: "system",
            content: SYSTEM_PROMPT
          },
          {
            role: "user",
            content: {
              locale: locale,
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
      allergens = normalize_array(raw["allergens"])
      items = Array(raw["items"]).map.with_index do |item, index|
        item_hash = item.is_a?(Hash) ? item : { "name" => item.to_s }
        {
          "name" => item_hash["name"].to_s.strip.presence || "Plato #{index + 1}",
          "description" => item_hash["description"].to_s.strip,
          "ingredients" => normalize_array(item_hash["ingredients"]),
          "allergens" => normalize_array(item_hash["allergens"])
        }
      end.reject { |item| item["name"].blank? }

      raise "openai_error: empty_items" if items.empty?

      {
        "title" => title.presence || "Menu del dia",
        "description" => description,
        "allergens" => allergens,
        "items" => items.first(4)
      }
    end

    def normalize_array(value)
      Array(value).flat_map { |entry| entry.to_s.split(",") }.map(&:strip).reject(&:blank?).uniq
    end
  end
end
