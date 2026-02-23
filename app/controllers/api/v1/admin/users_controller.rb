module Api
  module V1
    module Admin
      class UsersController < Api::V1::Admin::BaseController
        before_action :set_user, only: [ :block, :export ]

        def create
          user = User.new(user_params)
          authorize user

          password = params[:password].presence || Devise.friendly_token.first(12)
          user.password = password
          user.password_confirmation = password

          ActiveRecord::Base.transaction do
            user.save!
            if params[:tenant_id].present?
              Membership.create!(user: user, tenant_id: params[:tenant_id], role: params[:role] || "tenant_staff", active: true)
            end
            admin_flag = ActiveModel::Type::Boolean.new.cast(params[:system_admin])
            SystemRole.find_or_create_by!(user: user, role: :system_admin) if admin_flag
          end

          render json: {
            data: camelize_hash(user.as_json),
            temporaryPassword: password,
            requestId: request.request_id
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_error(code: "validation_error", message: "Invalid user", details: e.record.errors.full_messages, status: :unprocessable_entity)
        end

        def block
          authorize @user, :block?
          @user.update!(blocked_at: Time.current)
          render json: { success: true, requestId: request.request_id }, status: :ok
        end

        def export
          authorize @user

          payload = {
            id: @user.id,
            full_name: @user.full_name,
            email: @user.email,
            locale: @user.locale,
            gdpr_consent_at: @user.gdpr_consent_at,
            blocked_at: @user.blocked_at,
            memberships: @user.memberships.includes(:tenant).map do |membership|
              {
                tenant: membership.tenant.name,
                role: membership.role,
                active: membership.active
              }
            end
          }

          render json: { data: camelize_hash(payload), requestId: request.request_id }, status: :ok
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          params.require(:user).permit(:full_name, :email, :locale)
        end
      end
    end
  end
end
