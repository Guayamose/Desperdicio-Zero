module TenantPortal
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_current_tenant!

    private

    def tenant_scope(scope)
      policy_scope(scope).for_tenant(current_tenant)
    end

    def require_tenant_manager!
      unless current_user&.tenant_manager_in?(current_tenant)
        redirect_to tenant_dashboard_path, alert: "Solo los administradores del comedor pueden acceder a esta sección"
      end
    end
  end
end
