module TenantPortal
  class AlertsController < TenantPortal::BaseController
    def expirations
      authorize InventoryLot
      @expiring_lots = tenant_scope(InventoryLot).available.where(expires_on: Date.current..(Date.current + 2.days)).includes(:product).order(:expires_on)
      @expired_lots = tenant_scope(InventoryLot).where(expires_on: ..(Date.current - 1.day)).where.not(status: :consumed).includes(:product).order(:expires_on)
    end
  end
end
