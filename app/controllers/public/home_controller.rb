module Public
  class HomeController < Public::BaseController
    def show
      @operational_tenants = Tenant.operational.order(:name)
      @menus_today = DailyMenu.published.where(menu_date: Date.current).includes(:tenant).order(updated_at: :desc)

      @stats = {
        tenant_count: @operational_tenants.count,
        cities_count: @operational_tenants.where.not(city: nil).distinct.count(:city),
        menus_today_count: @menus_today.count
      }
    end
    def privacy
    end
  end
end
