module TenantPortal
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_current_tenant!
    before_action :check_must_change_password!

    private

    def check_must_change_password!
      return unless current_user&.must_change_password?
      return if controller_name == "passwords" && action_name.in?(%w[edit update])

      redirect_to edit_tenant_password_path, alert: "Debes establecer una nueva contraseña para continuar."
    end

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
