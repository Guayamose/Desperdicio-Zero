require "test_helper"

class PublicPortalTest < ActionDispatch::IntegrationTest
  test "public tenants index and detail are accessible" do
    tenant = Tenant.create!(name: "Comedor Norte", slug: "comedor-norte", status: :active)

    get root_path
    assert_response :success
    assert_includes response.body, "Social Kitchen"

    get public_tenants_path
    assert_response :success
    assert_includes response.body, "Comedores sociales disponibles"

    get public_tenant_path(tenant.slug)
    assert_response :success
    assert_includes response.body, "Comedor Norte"

    get public_tenant_menu_today_path(slug: tenant.slug)
    assert_response :success
  end
end
