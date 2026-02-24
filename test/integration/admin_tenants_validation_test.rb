require "test_helper"

class AdminTenantsValidationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      full_name: "Admin Tenants",
      email: "admin-tenants@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "es"
    )
    SystemRole.create!(user: @admin, role: :system_admin)
  end

  test "admin cannot create tenant without operating hours" do
    sign_in @admin

    assert_no_difference("Tenant.count") do
      post admin_tenants_path, params: {
        tenant: {
          name: "Comedor Sin Horario",
          slug: "comedor-sin-horario",
          status: "active",
          operating_hours_json: {
            "lunes" => "",
            "martes" => ""
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "debe incluir al menos un horario"
  end

  test "admin can create tenant with at least one operating hour" do
    sign_in @admin

    assert_difference("Tenant.count", 1) do
      post admin_tenants_path, params: {
        tenant: {
          name: "Comedor Centro",
          slug: "comedor-centro-admin",
          status: "active",
          address: "Calle Centro 20",
          operating_hours_json: {
            "lunes" => "08:00-16:00"
          }
        }
      }
    end

    tenant = Tenant.order(:id).last
    assert_redirected_to admin_tenant_path(tenant)
    assert_equal "08:00-16:00", tenant.operating_hours_json["lunes"]
  end
end
