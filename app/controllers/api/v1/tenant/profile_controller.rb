module Api
  module V1
    module Tenant
      class ProfileController < Api::V1::Tenant::BaseController
        skip_before_action :require_current_tenant!

        def show
          render json: { data: camelize_hash(profile_payload), requestId: request.request_id }, status: :ok
        end

        def update
          attrs = profile_params
          success = if attrs[:password].present?
            current_user.update(attrs)
          else
            current_user.update(attrs.except(:password, :password_confirmation, :current_password))
          end

          if success
            bypass_sign_in(current_user)
            render json: { data: camelize_hash(profile_payload), requestId: request.request_id }, status: :ok
          else
            render_error(code: "validation_error", message: "Invalid profile update", details: current_user.errors.full_messages, status: :unprocessable_entity)
          end
        end

        private

        def profile_params
          if params[:user].present?
            params.require(:user).permit(:full_name, :password, :password_confirmation, :current_password)
          else
            params.permit(:full_name, :password, :password_confirmation, :current_password)
          end
        end

        def profile_payload
          {
            user: {
              id: current_user.id,
              full_name: current_user.full_name,
              email: current_user.email,
              locale: current_user.locale,
              gdpr_consent_at: current_user.gdpr_consent_at,
              blocked_at: current_user.blocked_at,
              last_seen_at: current_user.last_seen_at,
              must_change_password: current_user.must_change_password,
              system_admin: current_user.system_admin?
            },
            current_tenant: current_tenant && {
              id: current_tenant.id,
              name: current_tenant.name,
              slug: current_tenant.slug
            },
            memberships: current_user.active_memberships.map do |membership|
              {
                id: membership.id,
                tenant_id: membership.tenant_id,
                role: membership.role,
                active: membership.active,
                tenant_name: membership.tenant&.name
              }
            end
          }
        end
      end
    end
  end
end
