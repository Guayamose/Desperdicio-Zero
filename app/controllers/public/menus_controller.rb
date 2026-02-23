module Public
  class MenusController < Public::BaseController
    def today
      @tenant = Tenant.operational.find_by!(slug: params[:slug])
      @menu = @tenant.daily_menus.published.find_by(menu_date: Date.current)
      @recent_menus = @tenant.daily_menus.published.where.not(id: @menu&.id).order(menu_date: :desc).limit(4)
    end
  end
end
