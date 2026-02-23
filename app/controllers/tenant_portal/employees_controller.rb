module TenantPortal
  class EmployeesController < TenantPortal::BaseController
    before_action :require_tenant_manager!

    def index
      @memberships = current_tenant.memberships.includes(:user).order(created_at: :desc)
    end
  end
end
