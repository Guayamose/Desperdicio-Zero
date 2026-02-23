module Public
  class TenantsController < Public::BaseController
    def index
      @tenants = Tenant.operational.order(:name)
      @stats = {
        tenant_count: @tenants.count,
        city_count: @tenants.where.not(city: nil).distinct.count(:city),
        menus_today: DailyMenu.published.where(menu_date: Date.current).count
      }
    end

    def show
      @tenant = Tenant.operational.find_by!(slug: params[:slug] || params[:id])
      @today_menu = @tenant.daily_menus.published.find_by(menu_date: Date.current)
      @recent_menus = @tenant.daily_menus.published.where.not(id: @today_menu&.id).order(menu_date: :desc).limit(3)
      @nearby_tenants = Tenant.operational.where.not(id: @tenant.id).order(:name).limit(3)
    end
  end
end
