module TenantPortal
  class SessionsController < TenantPortal::BaseController
    def switch
      tenant = Tenancy::TenantSwitchService.call(user: current_user, tenant_id: params[:tenant_id])

      if tenant
        switch_current_tenant!(tenant)
        redirect_back fallback_location: tenant_dashboard_path, notice: "Comedor cambiado a #{tenant.name}"
      else
        redirect_back fallback_location: tenant_dashboard_path, alert: "No puedes acceder a ese comedor"
      end
    end
  end
end
