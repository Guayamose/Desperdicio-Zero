module Inventory
  class BarcodeLookupService
    Result = Struct.new(:product, :source, :success, :error, keyword_init: true)

    def initialize(client: Integrations::OpenFoodFactsClient.new)
      @client = client
    end

    def call(raw_barcode)
      barcode = normalize_barcode(raw_barcode)
      return Result.new(product: nil, source: "invalid_barcode", success: false, error: "invalid_barcode") if invalid_barcode?(barcode)

      product = Product.find_by(barcode: barcode)
      if product
        refreshed_product = refresh_from_openfoodfacts_if_needed(product, barcode)
        if refreshed_product.present?
          return Result.new(product: refreshed_product, source: "openfoodfacts_refresh", success: true)
        end

        maybe_enqueue_sync(product)
        return Result.new(product: product, source: "cache", success: true)
      end

      external_data = @client.fetch_product(barcode)
      if external_data
        product = upsert_openfoodfacts_product(barcode, external_data)
        Result.new(product: product, source: "openfoodfacts", success: true)
      else
        enqueue_sync(barcode)
        product = Product.find_or_create_by!(barcode: barcode) do |candidate|
          candidate.name = "Producto #{barcode}"
          candidate.source = :manual
        end
        Result.new(product: product, source: "manual_fallback", success: false, error: "openfoodfacts_unavailable")
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(product: nil, source: "lookup_error", success: false, error: e.message)
    rescue StandardError => e
      Result.new(product: nil, source: "lookup_error", success: false, error: e.message)
    end

    private

    def normalize_barcode(raw_barcode)
      raw_barcode.to_s.gsub(/\s+/, "").strip
    end

    def invalid_barcode?(barcode)
      barcode.blank? || barcode.length < 6
    end

    def upsert_openfoodfacts_product(barcode, external_data)
      product = Product.find_or_initialize_by(barcode: barcode)
      product.assign_attributes(external_data.merge(source: :openfoodfacts, last_synced_at: Time.current))
      product.save!
      product
    rescue ActiveRecord::RecordNotUnique
      Product.find_by!(barcode: barcode)
    end

    def maybe_enqueue_sync(product)
      return unless product.barcode.present?
      return if product.openfoodfacts? && product.last_synced_at.present? && product.last_synced_at > 24.hours.ago

      enqueue_sync(product.barcode)
    end

    def refresh_from_openfoodfacts_if_needed(product, barcode)
      return nil unless should_refresh_now?(product)

      external_data = @client.fetch_product(barcode)
      return nil if external_data.blank?

      upsert_openfoodfacts_product(barcode, external_data)
    rescue StandardError
      nil
    end

    def should_refresh_now?(product)
      return true if placeholder_product_name?(product.name)
      return false if product.manual?

      product.last_synced_at.blank? || product.last_synced_at <= 24.hours.ago
    end

    def placeholder_product_name?(value)
      value.to_s.strip.match?(/\Aproducto\s+\d+\z/i)
    end

    def enqueue_sync(barcode)
      SyncProductFromBarcodeJob.perform_async(barcode)
    rescue StandardError
      nil
    end
  end
end
