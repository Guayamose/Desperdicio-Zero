module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :authenticate_api_user!
        before_action :require_system_admin!

        private

        def require_system_admin!
          return if system_admin?

          render_error(code: "forbidden", message: "System admin role required", status: :forbidden)
        end
      end
    end
  end
end
