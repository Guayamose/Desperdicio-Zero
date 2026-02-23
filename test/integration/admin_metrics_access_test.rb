require "test_helper"

class AdminMetricsAccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(full_name: "Admin", email: "admin@example.com", password: "Password123!", password_confirmation: "Password123!", locale: "es")
    SystemRole.create!(user: @admin, role: :system_admin)

    @staff = User.create!(full_name: "Staff", email: "staff@example.com", password: "Password123!", password_confirmation: "Password123!", locale: "es")
  end

  test "system admin can access admin metrics" do
    sign_in @admin
    get admin_metrics_path
    assert_response :success
  end

  test "non-admin user is redirected from admin metrics" do
    sign_in @staff
    get admin_metrics_path
    assert_redirected_to root_path
  end
end
