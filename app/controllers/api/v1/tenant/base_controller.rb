module Api
  module V1
    module Tenant
      class BaseController < Api::V1::BaseController
        before_action :authenticate_api_user!
        before_action :require_current_tenant!

        private

        def tenant_scope(scope)
          policy_scope(scope).for_tenant(current_tenant)
        end

        def require_current_tenant!
          return if current_tenant.present?

          render_error(code: "tenant_required", message: "Select an active tenant", status: :forbidden)
        end
      end
    end
  end
end
