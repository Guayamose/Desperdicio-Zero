module Api
  module V1
    module Tenant
      class EmployeesController < Api::V1::Tenant::BaseController
        before_action :require_tenant_manager!
        before_action :set_membership, only: [ :update, :destroy ]

        def index
          memberships = current_tenant.memberships.includes(:user).order(created_at: :desc)

          render json: {
            data: memberships.map { |membership| camelize_hash(membership_payload(membership)) },
            requestId: request.request_id
          }, status: :ok
        end

        def create
          user = User.new(user_params)
          temporary_password = Devise.friendly_token.first(12)
          user.password = temporary_password
          user.password_confirmation = temporary_password
          user.must_change_password = true

          membership = nil
          ActiveRecord::Base.transaction do
            user.save!
            membership = Membership.create!(
              user: user,
              tenant: current_tenant,
              role: requested_role,
              active: true
            )
          end

          render json: {
            data: camelize_hash(membership_payload(membership)),
            temporaryPassword: temporary_password,
            requestId: request.request_id
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_error(code: "validation_error", message: "Invalid employee", details: e.record.errors.full_messages, status: :unprocessable_entity)
        end

        def update
          @membership.update!(role: requested_role)
          render json: { data: camelize_hash(membership_payload(@membership.reload)), requestId: request.request_id }, status: :ok
        rescue ActiveRecord::RecordInvalid => e
          render_error(code: "validation_error", message: "Invalid membership", details: e.record.errors.full_messages, status: :unprocessable_entity)
        end

        def destroy
          if @membership.user_id == current_user.id
            return render_error(code: "forbidden", message: "You cannot remove yourself", status: :forbidden)
          end

          user = @membership.user
          @membership.destroy!
          user.destroy! if user.memberships.reload.empty?

          render json: { success: true, requestId: request.request_id }, status: :ok
        end

        private

        def set_membership
          @membership = current_tenant.memberships.includes(:user).find(params[:id])
        end

        def require_tenant_manager!
          return if current_user&.tenant_manager_in?(current_tenant)

          render_error(code: "forbidden", message: "Tenant manager role required", status: :forbidden)
        end

        def user_params
          if params[:user].present?
            params.require(:user).permit(:full_name, :email, :locale)
          else
            params.permit(:full_name, :email, :locale)
          end
        end

        def requested_role
          role = params.dig(:membership, :role).presence || params[:role].presence || "tenant_staff"
          Membership.roles.key?(role) ? role : "tenant_staff"
        end

        def membership_payload(membership)
          {
            id: membership.id,
            role: membership.role,
            active: membership.active,
            created_at: membership.created_at,
            user: {
              id: membership.user.id,
              full_name: membership.user.full_name,
              email: membership.user.email,
              locale: membership.user.locale,
              blocked_at: membership.user.blocked_at,
              must_change_password: membership.user.must_change_password
            }
          }
        end
      end
    end
  end
end
