require "test_helper"

class TenantMenuGeneratorPageTest < ActionDispatch::IntegrationTest
  test "tenant user can open generator page and see prioritized inventory" do
    tenant = Tenant.create!(
      name: "Comedor Centro",
      slug: "comedor-centro",
      status: :active,
      operating_hours_json: { "lunes" => "08:00-16:00" }
    )
    user = User.create!(
      full_name: "Manager Centro",
      email: "manager-centro@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "es"
    )
    Membership.create!(user: user, tenant: tenant, role: :tenant_manager, active: true)

    product = Product.create!(name: "Arroz integral", barcode: "8419991110001", source: :manual)
    InventoryLot.create!(
      tenant: tenant,
      product: product,
      expires_on: Date.current + 1.day,
      quantity: 5,
      unit: :kg,
      status: :available,
      source: :donation
    )

    sign_in user
    get generate_tenant_menus_path(date: Date.current)

    assert_response :success
    assert_includes response.body, "Menu diario guiado"
    assert_includes response.body, "Arroz integral"
    assert_includes response.body, "Paso 2 y 3: Preview y generacion"
    assert_includes response.body, "Generando menu con IA"
    assert_includes response.body, "Cancelar y volver atras"
  end
end
