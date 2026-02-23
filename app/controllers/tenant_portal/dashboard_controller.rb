module TenantPortal
  class DashboardController < TenantPortal::BaseController
    def show
      authorize current_tenant, :show?, policy_class: TenantPolicy

      @expiring_count = current_tenant.inventory_lots.critical_expiration.count
      @inventory_count = current_tenant.inventory_lots.count
      @today_menu = current_tenant.daily_menus.find_by(menu_date: Date.current)
      @latest_generation = current_tenant.menu_generations.order(created_at: :desc).first
    end
  end
end
