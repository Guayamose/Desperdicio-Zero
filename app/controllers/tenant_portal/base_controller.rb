module TenantPortal
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_current_tenant!

    private

    def tenant_scope(scope)
      policy_scope(scope).for_tenant(current_tenant)
    end
  end
end
