require "test_helper"

class Inventory::BarcodeLookupServiceTest < ActiveSupport::TestCase
  class SuccessfulClient
    def fetch_product(_barcode)
      {
        barcode: "8411111111111",
        name: "Arroz integral",
        brand: "Solidario",
        category: "granos",
        ingredients_text: "arroz integral",
        allergens_json: [],
        nutrition_json: {}
      }
    end
  end

  class FailingClient
    def fetch_product(_barcode)
      nil
    end
  end

  test "returns invalid for short barcode" do
    result = Inventory::BarcodeLookupService.new(client: FailingClient.new).call("123")

    assert_equal false, result.success
    assert_equal "invalid_barcode", result.source
    assert_nil result.product
  end

  test "creates product from openfoodfacts data" do
    result = Inventory::BarcodeLookupService.new(client: SuccessfulClient.new).call("8411111111111")

    assert_equal true, result.success
    assert_equal "openfoodfacts", result.source
    assert_equal "Arroz integral", result.product.name
    assert_equal "openfoodfacts", result.product.source
  end

  test "falls back to manual product when openfoodfacts is unavailable" do
    result = Inventory::BarcodeLookupService.new(client: FailingClient.new).call("8412222222222")

    assert_equal false, result.success
    assert_equal "manual_fallback", result.source
    assert_equal "manual", result.product.source
    assert_equal "8412222222222", result.product.barcode
  end
end
