require "test_helper"

class TenantApiInventoryTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(full_name: "Empleado A", email: "empleado-a@example.com", password: "Password123!", password_confirmation: "Password123!", locale: "es")
    @tenant_a = Tenant.create!(name: "A", slug: "a", status: :active, operating_hours_json: { "lunes" => "08:00-16:00" })
    @tenant_b = Tenant.create!(name: "B", slug: "b", status: :active, operating_hours_json: { "lunes" => "08:00-16:00" })

    Membership.create!(user: @user, tenant: @tenant_a, role: :tenant_staff, active: true)

    product_a = Product.create!(name: "Arroz", barcode: "111", source: :manual)
    product_b = Product.create!(name: "Pasta", barcode: "222", source: :manual)

    InventoryLot.create!(tenant: @tenant_a, product: product_a, expires_on: Date.current + 1.day, quantity: 5, unit: :kg, status: :available, source: :donation)
    InventoryLot.create!(tenant: @tenant_b, product: product_b, expires_on: Date.current + 1.day, quantity: 9, unit: :kg, status: :available, source: :donation)
  end

  test "inventory API only returns current tenant lots" do
    sign_in @user

    get "/api/v1/tenant/inventory/lots"
    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal 1, payload.fetch("data").size
    assert_equal "Arroz", payload.fetch("data").first.dig("product", "name")
  end
end
