module Api
  module V1
    module Tenant
      class MenusController < Api::V1::Tenant::BaseController
        before_action :set_menu_by_id, only: [ :update, :publish ]

        def generate
          menu_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
          menu = current_tenant.daily_menus.find_or_initialize_by(menu_date: menu_date)
          authorize menu, :create?

          if menu.persisted?
            return render_error(
              code: "menu_already_exists",
              message: "Only one menu per day is allowed",
              status: :conflict
            )
          end

          generated = Menus::GenerateDailyMenuService.new(tenant: current_tenant, user: current_user).call(date: menu_date)
          render_resource(generated.as_json(include: :daily_menu_items), status: :created)
        rescue Date::Error
          render_error(code: "invalid_date", message: "Invalid date", status: :unprocessable_entity)
        end

        def show
          menu_date = Date.parse(params[:date])
          menu = tenant_scope(DailyMenu).find_by!(menu_date: menu_date)
          authorize menu
          render_resource(menu.as_json(include: :daily_menu_items))
        rescue Date::Error
          render_error(code: "invalid_date", message: "Invalid date", status: :unprocessable_entity)
        end

        def update
          authorize @menu

          if @menu.update(menu_params)
            render_resource(@menu.as_json(include: :daily_menu_items))
          else
            render_error(code: "validation_error", message: "Invalid menu", details: @menu.errors.full_messages, status: :unprocessable_entity)
          end
        end

        def publish
          authorize @menu, :publish?
          @menu.update!(status: :published)
          render_resource(@menu.as_json(include: :daily_menu_items))
        end

        private

        def set_menu_by_id
          @menu = tenant_scope(DailyMenu).find(params[:id])
        end

        def menu_params
          raw = params.require(:daily_menu).permit(
            :title,
            :description,
            allergens_json: [],
            daily_menu_items_attributes: [ :id, :name, :description, :position, :_destroy, { ingredients_json: [], allergens_json: [] } ]
          ).to_h

          raw["allergens_json"] = normalize_csv_array(raw["allergens_json"])

          items = raw["daily_menu_items_attributes"] || {}
          items.each_value do |item|
            item["ingredients_json"] = normalize_csv_array(item["ingredients_json"])
            item["allergens_json"] = normalize_csv_array(item["allergens_json"])
          end

          raw
        end

        def normalize_csv_array(value)
          return value if value.is_a?(Array) && value.none? { |v| v.to_s.include?(",") }

          Array(value).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
        end
      end
    end
  end
end
