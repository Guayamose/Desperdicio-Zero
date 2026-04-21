module Api
  module V1
    module Public
      class TenantsController < Api::V1::BaseController
        def index
          tenants = Tenant.operational.order(:name).to_a
          today_menus = published_today_menus_for(tenants)

          render_collection(tenants.map { |tenant| tenant_payload(tenant, today_menus[tenant.id]) })
        end

        def show
          tenant = Tenant.operational.find_by!(slug: params[:slug] || params[:id])
          render_resource(tenant_payload(tenant, published_today_menu_for(tenant)))
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

        private

        def published_today_menus_for(tenants)
          DailyMenu.published
            .today
            .where(tenant_id: tenants.map(&:id))
            .select(:tenant_id, :title, :menu_date)
            .index_by(&:tenant_id)
        end

        def published_today_menu_for(tenant)
          tenant.daily_menus.published.today.select(:tenant_id, :title, :menu_date).first
        end

        def tenant_payload(tenant, today_menu)
          tenant.as_json.merge(
            today_menu_published: today_menu.present?,
            today_menu_title: today_menu&.title,
            today_menu_date: today_menu&.menu_date
          )
        end
      end
    end
  end
end
