require "test_helper"

class PublicPortalTest < ActionDispatch::IntegrationTest
  test "public tenants index and detail are accessible" do
    tenant = Tenant.create!(
      name: "Comedor Norte",
      slug: "comedor-norte",
      status: :active,
      address: "Calle Norte 10",
      city: "Madrid",
      operating_hours_json: {
        "lunes" => "08:00-16:00",
        "martes" => "08:00-16:00"
      }
    )

    get root_path
    assert_response :success
    assert_includes response.body, "Social Kitchen"

    get public_tenants_path
    assert_response :success
    assert_includes response.body, "Directorio de Comedores Sociales"
    assert_includes response.body, "Lunes: 08:00-16:00"

    get public_tenant_path(tenant.slug)
    assert_response :success
    assert_includes response.body, "Comedor Norte"
    assert_includes response.body, "Lunes:"
    assert_includes response.body, "08:00-16:00"

    get public_tenant_menu_today_path(slug: tenant.slug)
    assert_response :success
  end
end
