module Integrations
  class OpenFoodFactsClient
    BASE_URL = "https://world.openfoodfacts.org".freeze
    REQUEST_FIELDS = %w[
      product_name
      product_name_es
      generic_name
      brands
      categories
      categories_tags
      ingredients_text
      ingredients_text_es
      allergens
      allergens_tags
      nutriments
    ].freeze

    def initialize(connection: nil)
      @connection = connection || Faraday.new(url: BASE_URL) do |f|
        f.options.timeout = 1.5
        f.options.open_timeout = 1.5
        f.response :raise_error
        f.headers["User-Agent"] = "SocialKitchen/1.0 (+https://socialkitchen.local)"
        f.adapter Faraday.default_adapter
      end
    end

    def fetch_product(raw_barcode)
      barcode = normalize_barcode(raw_barcode)
      return nil if barcode.blank?

      cached = Rails.cache.read(cache_key(barcode))
      return cached if cached

      attempts = 0
      begin
        attempts += 1
        response = @connection.get("/api/v2/product/#{barcode}.json", fields: REQUEST_FIELDS.join(","))
        payload = JSON.parse(response.body)
        return nil unless payload["status"] == 1

        product = normalize(payload.fetch("product", {}), barcode)
        Rails.cache.write(cache_key(barcode), product, expires_in: 24.hours)
        product
      rescue Faraday::Error, JSON::ParserError
        retry if attempts < 3
        nil
      end
    end

    private

    def cache_key(barcode)
      "off:product:#{barcode}"
    end

    def normalize_barcode(raw_barcode)
      raw_barcode.to_s.gsub(/\s+/, "").strip
    end

    def normalize(raw, barcode)
      allergens = Array(raw["allergens_tags"]).map { |tag| normalize_tag(tag) }.reject(&:blank?).uniq
      categories = Array(raw["categories_tags"]).map { |tag| normalize_tag(tag) }.reject(&:blank?)
      brand = raw["brands"].to_s.split(",").map(&:strip).reject(&:blank?).first
      ingredients = raw["ingredients_text_es"].presence || raw["ingredients_text"]

      {
        barcode: barcode,
        name: raw["product_name_es"].presence || raw["product_name"].presence || raw["generic_name"].presence || "Producto #{barcode}",
        brand: brand,
        category: categories.first || raw["categories"].to_s.split(",").first&.strip,
        ingredients_text: ingredients,
        allergens_json: allergens,
        nutrition_json: raw["nutriments"].is_a?(Hash) ? raw["nutriments"] : {}
      }
    end

    def normalize_tag(tag)
      tag.to_s.split(":").last.to_s.tr("-", " ").strip
    end
  end
end
