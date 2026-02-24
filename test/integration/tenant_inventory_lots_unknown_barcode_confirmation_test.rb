require "test_helper"
require "minitest/mock"

class TenantInventoryLotsUnknownBarcodeConfirmationTest < ActionDispatch::IntegrationTest
  class FakeOffClient
    def initialize(response:)
      @response = response
    end

    def fetch_product(_barcode)
      @response
    end
  end

  setup do
    @user = User.create!(
      full_name: "Gestor Inventario",
      email: "gestor-inventario@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "es"
    )
    @tenant = Tenant.create!(
      name: "Comedor Norte",
      slug: "comedor-norte",
      status: :active,
      operating_hours_json: { "lunes" => "08:00-16:00" }
    )
    Membership.create!(user: @user, tenant: @tenant, role: :tenant_manager, active: true)
  end

  test "blocks create when barcode is unknown and confirmation is missing" do
    sign_in @user

    assert_no_difference("InventoryLot.count") do
      Integrations::OpenFoodFactsClient.stub(:new, FakeOffClient.new(response: nil)) do
        post tenant_inventory_lots_path, params: inventory_lot_payload(barcode: "9999999999990", confirmed: "0")
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "no existe en OpenFoodFacts"
  end

  test "allows create when barcode is unknown but confirmation is explicit" do
    sign_in @user

    product = Product.create!(name: "Producto 999", barcode: "9999999999991", source: :manual)
    result = Inventory::BarcodeLookupService::Result.new(
      product: product,
      source: "manual_fallback",
      success: false,
      error: "openfoodfacts_unavailable"
    )
    lookup_service = Object.new
    lookup_service.define_singleton_method(:call) { |_barcode| result }

    assert_difference("InventoryLot.count", 1) do
      Inventory::BarcodeLookupService.stub(:new, -> { lookup_service }) do
        post tenant_inventory_lots_path, params: inventory_lot_payload(barcode: product.barcode, confirmed: "1")
      end
    end

    created_lot = InventoryLot.order(:id).last
    assert_redirected_to tenant_inventory_lot_path(created_lot)
    assert_equal product.id, created_lot.product_id
  end

  private

  def inventory_lot_payload(barcode:, confirmed:)
    {
      inventory_lot: {
        barcode: barcode,
        unknown_barcode_confirmed: confirmed,
        product_name: "Producto manual",
        expires_on: Date.current + 7.days,
        quantity: 1,
        unit: "unit",
        status: "available",
        received_on: Date.current,
        source: "donation",
        notes: ""
      }
    }
  end
end
