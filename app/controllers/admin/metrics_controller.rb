module Admin
  class MetricsController < Admin::BaseController
    def show
      authorize Tenant, :index?

      @metrics = {
        tenants: Tenant.count,
        active_tenants: Tenant.active.count,
        users: User.count,
        blocked_users: User.where.not(blocked_at: nil).count,
        inventory_lots: InventoryLot.count,
        expired_lots: InventoryLot.expired.count,
        generated_menus_today: DailyMenu.where(menu_date: Date.current).count,
        menu_fallbacks: MenuGeneration.fallback_manual.where("created_at >= ?", 7.days.ago).count
      }
    end
  end
end
