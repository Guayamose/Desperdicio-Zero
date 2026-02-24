module Admin
  class InventoriesController < Admin::BaseController
    def show
      authorize InventoryLot, :index?

      @tenants_inventory = Tenant.order(:name).map do |tenant|
        lots = InventoryLot.where(tenant: tenant).includes(:product).order(:expires_on)

        {
          tenant: tenant,
          total: lots.count,
          available: lots.count { |l| l.available? },
          expiring_soon: lots.count { |l| l.available? && l.expires_on <= Date.current + 3.days },
          lots: lots
        }
      end

      @global_total     = InventoryLot.count
      @global_available = InventoryLot.available.count
      @global_expiring  = InventoryLot.critical_expiration.count
    end
  end
end
