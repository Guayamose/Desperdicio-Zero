class SyncProductFromBarcodeJob
  include Sidekiq::Job

  sidekiq_options retry: 5, queue: :default

  def perform(barcode)
    client = Integrations::OpenFoodFactsClient.new
    data = client.fetch_product(barcode)
    return if data.blank?

    product = Product.find_or_initialize_by(barcode: barcode)
    product.assign_attributes(data.merge(source: :openfoodfacts, last_synced_at: Time.current))
    product.save!
  end
end
