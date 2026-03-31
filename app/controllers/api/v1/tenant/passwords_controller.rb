module Api
  module V1
    module Tenant
      class PasswordsController < Api::V1::Tenant::BaseController
        skip_before_action :require_current_tenant!

        def update
          password = password_params[:password]
          password_confirmation = password_params[:password_confirmation]

          if password != password_confirmation
            return render_error(code: "validation_error", message: "Passwords do not match", status: :unprocessable_entity)
          end

          if current_user.update(password: password, password_confirmation: password_confirmation, must_change_password: false)
            bypass_sign_in(current_user)
            render json: {
              data: {
                mustChangePassword: current_user.must_change_password
              },
              requestId: request.request_id
            }, status: :ok
          else
            render_error(code: "validation_error", message: "Invalid password update", details: current_user.errors.full_messages, status: :unprocessable_entity)
          end
        end

        private

        def password_params
          if params[:user].present?
            params.require(:user).permit(:password, :password_confirmation)
          else
            params.permit(:password, :password_confirmation)
          end
        end
      end
    end
  end
end
