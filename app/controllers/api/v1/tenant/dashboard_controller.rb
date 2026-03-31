module Api
  module V1
    module Tenant
      class DashboardController < Api::V1::Tenant::BaseController
        def show
          authorize current_tenant, :show?, policy_class: TenantPolicy

          today_menu = current_tenant.daily_menus.includes(:daily_menu_items).find_by(menu_date: Date.current)
          latest_generation = current_tenant.menu_generations.order(created_at: :desc).first

          payload = {
            tenant: {
              id: current_tenant.id,
              name: current_tenant.name,
              city: current_tenant.city,
              country: current_tenant.country
            },
            metrics: {
              inventory_count: current_tenant.inventory_lots.count,
              expiring_count: current_tenant.inventory_lots.critical_expiration.count,
              today_menu_count: today_menu.present? ? 1 : 0,
              latest_generation_latency_ms: latest_generation&.latency_ms
            },
            today_menu: today_menu&.as_json(include: :daily_menu_items),
            latest_generation: latest_generation&.as_json
          }

          render json: { data: camelize_hash(payload), requestId: request.request_id }, status: :ok
        end
      end
    end
  end
end
