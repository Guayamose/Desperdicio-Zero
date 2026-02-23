module Api
  module V1
    module Public
      class TenantsController < Api::V1::BaseController
        def index
          render_collection(Tenant.operational.order(:name))
        end

        def show
          tenant = Tenant.operational.find_by!(slug: params[:slug] || params[:id])
          render_resource(tenant)
        end

        def menu_today
          tenant = Tenant.operational.find_by!(slug: params[:slug] || params[:id])
          menu = tenant.daily_menus.published.find_by(menu_date: Date.current)

          if menu
            render_resource(menu.as_json(include: :daily_menu_items))
          else
            render_error(code: "not_found", message: "No menu published for today", status: :not_found)
          end
        end
      end
    end
  end
end
