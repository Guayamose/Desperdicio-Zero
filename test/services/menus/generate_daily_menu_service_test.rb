require "test_helper"

class Menus::GenerateDailyMenuServiceTest < ActiveSupport::TestCase
  class FailingAiClient
    def generate_menu(ingredients:, locale:)
      raise "simulated_failure"
    end

    def model
      "gpt-test"
    end
  end

  test "falls back to manual draft when AI fails" do
    tenant = Tenant.create!(
      name: "Comedor Sur",
      slug: "comedor-sur",
      status: :active,
      operating_hours_json: { "lunes" => "08:00-16:00" }
    )
    user = User.create!(full_name: "Manager", email: "manager@example.com", password: "Password123!", password_confirmation: "Password123!", locale: "es")
    Membership.create!(user: user, tenant: tenant, role: :tenant_manager, active: true)

    product = Product.create!(name: "Lentejas", barcode: "333", source: :manual)
    InventoryLot.create!(tenant: tenant, product: product, expires_on: Date.current + 1.day, quantity: 3, unit: :kg, status: :available, source: :donation)

    menu = Menus::GenerateDailyMenuService.new(tenant: tenant, user: user, ai_client: FailingAiClient.new).call(date: Date.current)

    assert menu.persisted?
    assert_equal "manual", menu.generated_by
    assert_equal "draft", menu.status
    assert_equal Date.current, menu.menu_date
  end

  test "fallback still works when async retry is disabled" do
    tenant = Tenant.create!(
      name: "Comedor Este",
      slug: "comedor-este",
      status: :active,
      operating_hours_json: { "lunes" => "08:00-16:00" }
    )
    user = User.create!(full_name: "Manager", email: "manager2@example.com", password: "Password123!", password_confirmation: "Password123!", locale: "es")
    Membership.create!(user: user, tenant: tenant, role: :tenant_manager, active: true)

    product = Product.create!(name: "Arroz", barcode: "444", source: :manual)
    InventoryLot.create!(tenant: tenant, product: product, expires_on: Date.current + 1.day, quantity: 3, unit: :kg, status: :available, source: :donation)

    menu = Menus::GenerateDailyMenuService.new(tenant: tenant, user: user, ai_client: FailingAiClient.new).call(
      date: Date.current,
      allow_async_retry: false
    )

    assert menu.persisted?
    assert_equal "manual", menu.generated_by
  end
end
