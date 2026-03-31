module Api
  module V1
    module Auth
      class SessionsController < Api::V1::BaseController
        before_action :authenticate_api_user!, only: [ :destroy, :me, :switch_tenant ]

        def create
          email = params.require(:email).to_s.downcase.strip
          password = params.require(:password).to_s
          user = User.find_for_authentication(email: email)

          unless user&.valid_password?(password) && user.active_for_authentication?
            return render_error(code: "invalid_credentials", message: "Invalid email or password", status: :unauthorized)
          end

          sign_in(user)
          ensure_default_tenant!(user)
          render_session_payload(user)
        end

        def destroy
          sign_out(current_user)
          reset_session
          render json: { success: true, requestId: request.request_id }, status: :ok
        end

        def me
          render_session_payload(current_user)
        end

        def switch_tenant
          tenant = Tenancy::TenantSwitchService.call(user: current_user, tenant_id: params[:tenant_id])
          unless tenant
            return render_error(code: "forbidden", message: "No access to requested tenant", status: :forbidden)
          end

          switch_current_tenant!(tenant)
          render_session_payload(current_user)
        end

        private

        def ensure_default_tenant!(user)
          return if session[:current_tenant_id].present?

          default_membership = user.active_memberships.first
          session[:current_tenant_id] = default_membership&.tenant_id
        end

        def render_session_payload(user)
          memberships = user.active_memberships.map do |membership|
            {
              id: membership.id,
              tenant_id: membership.tenant_id,
              role: membership.role,
              active: membership.active,
              tenant: membership.tenant && {
                id: membership.tenant.id,
                name: membership.tenant.name,
                slug: membership.tenant.slug,
                status: membership.tenant.status,
                city: membership.tenant.city,
                country: membership.tenant.country
              }
            }
          end

          payload = {
            user: {
              id: user.id,
              full_name: user.full_name,
              email: user.email,
              locale: user.locale,
              blocked_at: user.blocked_at,
              must_change_password: user.must_change_password,
              system_admin: user.system_admin?
            },
            current_tenant: current_tenant && {
              id: current_tenant.id,
              name: current_tenant.name,
              slug: current_tenant.slug,
              status: current_tenant.status
            },
            memberships: memberships
          }

          render json: { data: camelize_hash(payload), requestId: request.request_id }, status: :ok
        end
      end
    end
  end
end
