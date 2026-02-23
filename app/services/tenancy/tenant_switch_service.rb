module Tenancy
  class TenantSwitchService
    def self.call(user:, tenant_id:)
      membership = user.active_memberships.find_by(tenant_id: tenant_id)
      membership&.tenant
    end
  end
end
