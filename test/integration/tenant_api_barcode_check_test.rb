require "test_helper"
require "minitest/mock"

class TenantApiBarcodeCheckTest < ActionDispatch::IntegrationTest
  class FakeClient
    attr_reader :last_barcode

    def initialize(response:)
      @response = response
      @last_barcode = nil
    end

    def fetch_product(barcode)
      @last_barcode = barcode
      @response
    end
  end

  setup do
    @user = User.create!(
      full_name: "Empleado A",
      email: "empleado-barcode-check@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "es"
    )
    @tenant = Tenant.create!(
      name: "Comedor Central",
      slug: "comedor-central",
      status: :active,
      operating_hours_json: { "lunes" => "08:00-16:00" }
    )
    Membership.create!(user: @user, tenant: @tenant, role: :tenant_staff, active: true)
  end

  test "barcode check returns exists true when openfoodfacts has product" do
    sign_in @user

    client = FakeClient.new(response: { barcode: "8411111111111", name: "Arroz" })

    Integrations::OpenFoodFactsClient.stub(:new, client) do
      post "/api/v1/tenant/inventory/barcode_check", params: { barcode: " 8411111111111 " }, as: :json
    end

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal "8411111111111", client.last_barcode
    assert_equal "8411111111111", payload.dig("data", "barcode")
    assert_equal true, payload.dig("data", "exists")
  end

  test "barcode check returns exists false when openfoodfacts has no product" do
    sign_in @user

    client = FakeClient.new(response: nil)

    Integrations::OpenFoodFactsClient.stub(:new, client) do
      post "/api/v1/tenant/inventory/barcode_check", params: { barcode: "8419999999999" }, as: :json
    end

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal "8419999999999", client.last_barcode
    assert_equal "8419999999999", payload.dig("data", "barcode")
    assert_equal false, payload.dig("data", "exists")
  end

  test "barcode check returns validation error for short barcode" do
    sign_in @user

    post "/api/v1/tenant/inventory/barcode_check", params: { barcode: "123" }, as: :json

    assert_response :unprocessable_content
    payload = JSON.parse(response.body)
    assert_equal "invalid_barcode", payload["code"]
  end
end
