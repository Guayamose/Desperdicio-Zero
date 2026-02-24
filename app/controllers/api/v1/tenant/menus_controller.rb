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
            nutrition_summary_json: {},
            planning_notes_json: {},
            dietary_guidance_json: [ :halalStatus, :religiousNotes, { haramRisks: [], vegetarianOptions: [], veganOptions: [] } ],
            daily_menu_items_attributes: [
              :id,
              :name,
              :description,
              :position,
              :servings,
              :repetitions,
              :religious_notes,
              :_destroy,
              { ingredients_json: [], allergens_json: [], dietary_flags_json: [], nutrition_json: {}, inventory_usage_json: [ :lotId, :product, :quantity, :unit ] }
            ]
          ).to_h

          raw["allergens_json"] = normalize_csv_array(raw["allergens_json"]) if raw.key?("allergens_json")
          raw["nutrition_summary_json"] = normalize_hash(raw["nutrition_summary_json"]) if raw.key?("nutrition_summary_json")
          raw["planning_notes_json"] = normalize_hash(raw["planning_notes_json"]) if raw.key?("planning_notes_json")
          raw["dietary_guidance_json"] = normalize_dietary_guidance(raw["dietary_guidance_json"]) if raw.key?("dietary_guidance_json")

          items = raw["daily_menu_items_attributes"] || {}
          items.each_value do |item|
            item["ingredients_json"] = normalize_csv_array(item["ingredients_json"]) if item.key?("ingredients_json")
            item["allergens_json"] = normalize_csv_array(item["allergens_json"]) if item.key?("allergens_json")
            item["dietary_flags_json"] = normalize_csv_array(item["dietary_flags_json"]) if item.key?("dietary_flags_json")
            item["nutrition_json"] = normalize_hash(item["nutrition_json"]) if item.key?("nutrition_json")
            item["inventory_usage_json"] = normalize_inventory_usage(item["inventory_usage_json"]) if item.key?("inventory_usage_json")
            item["servings"] = normalize_positive_integer(item["servings"], default: 1) if item.key?("servings")
            item["repetitions"] = normalize_positive_integer(item["repetitions"], default: 1) if item.key?("repetitions")
          end

          raw
        end

        def normalize_csv_array(value)
          return value if value.is_a?(Array) && value.none? { |v| v.to_s.include?(",") }

          Array(value).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
        end

        def normalize_hash(value)
          value.is_a?(Hash) ? value : {}
        end

        def normalize_dietary_guidance(value)
          return {} unless value.is_a?(Hash)

          {
            "halalStatus" => value["halalStatus"].to_s.strip,
            "religiousNotes" => value["religiousNotes"].to_s.strip,
            "haramRisks" => normalize_csv_array(value["haramRisks"]),
            "vegetarianOptions" => normalize_csv_array(value["vegetarianOptions"]),
            "veganOptions" => normalize_csv_array(value["veganOptions"])
          }.compact
        end

        def normalize_inventory_usage(value)
          entries = value.is_a?(Hash) ? value.values : Array(value)

          entries.map do |usage|
            normalized = usage.is_a?(Hash) ? usage.to_h : {}
            next if normalized.blank?

            {
              "lotId" => normalized["lotId"].presence || normalized[:lotId],
              "product" => normalized["product"].presence || normalized[:product],
              "quantity" => normalized["quantity"].presence || normalized[:quantity],
              "unit" => normalized["unit"].presence || normalized[:unit]
            }.compact
          end.compact
        end

        def normalize_positive_integer(value, default:)
          parsed = Integer(value)
          parsed.positive? ? parsed : default
        rescue ArgumentError, TypeError
          default
        end
      end
    end
  end
end
