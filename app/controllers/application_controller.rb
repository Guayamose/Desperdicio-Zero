class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :set_current_context
  after_action :reset_current_context

  helper_method :current_tenant, :system_admin?

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized

  private

  def set_current_context
    Current.request_id = request.request_id
    Current.user = current_user
    Current.tenant = current_tenant
    current_user&.update_column(:last_seen_at, Time.current)
  end

  def reset_current_context
    Current.reset
  end

  def current_tenant
    return unless current_user

    session_tenant_id = session[:current_tenant_id]
    @current_tenant ||= begin
      membership = if session_tenant_id.present?
                     current_user.active_memberships.find_by(tenant_id: session_tenant_id)
                   else
                     current_user.active_memberships.first
                   end
      session[:current_tenant_id] = membership&.tenant_id
      membership&.tenant
    end
  end

  def switch_current_tenant!(tenant)
    return unless current_user&.in_tenant?(tenant)

    session[:current_tenant_id] = tenant.id
    @current_tenant = tenant
    Current.tenant = tenant
  end

  def require_current_tenant!
    return if current_tenant.present? || system_admin?

    redirect_to root_path, alert: "Selecciona un comedor activo para continuar"
  end

  def system_admin?
    current_user&.system_admin?
  end

  def require_system_admin!
    return if system_admin?

    redirect_to root_path, alert: "No tienes permisos de administrador global"
  end

  def handle_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "No autorizado" }
      format.json { render json: { code: "forbidden", message: "No autorizado", requestId: request.request_id }, status: :forbidden }
    end
  end
end
