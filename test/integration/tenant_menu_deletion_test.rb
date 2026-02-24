require "test_helper"

class TenantMenuDeletionTest < ActionDispatch::IntegrationTest
  test "tenant manager can delete a published menu" do
    tenant = Tenant.create!(name: "Comedor Norte", slug: "comedor-norte", status: :active)
    user = User.create!(
      full_name: "Manager Norte",
      email: "manager-norte@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "es"
    )
    Membership.create!(user: user, tenant: tenant, role: :tenant_manager, active: true)

    menu = tenant.daily_menus.create!(
      menu_date: Date.current,
      title: "Menu publicado",
      description: "Menu de prueba",
      status: :published,
      generated_by: :manual,
      created_by: user
    )

    sign_in user

    assert_difference -> { tenant.daily_menus.count }, -1 do
      delete tenant_menu_path(menu)
    end

    assert_redirected_to tenant_menus_path
  end
end
