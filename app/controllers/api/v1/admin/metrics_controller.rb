module Api
  module V1
    module Admin
      class MetricsController < Api::V1::Admin::BaseController
        def show
          authorize Tenant, :index?

          metrics = {
            tenants: Tenant.count,
            active_tenants: Tenant.active.count,
            users: User.count,
            inventory_lots: InventoryLot.count,
            expired_lots: InventoryLot.expired.count,
            menus_today: DailyMenu.where(menu_date: Date.current).count,
            ai_success_ratio: success_ratio
          }

          render json: { data: camelize_hash(metrics), requestId: request.request_id }, status: :ok
        end

        private

        def success_ratio
          last_week = MenuGeneration.where("created_at >= ?", 7.days.ago)
          total = last_week.count
          return 0.0 if total.zero?

          (last_week.succeeded.count.to_f / total).round(3)
        end
      end
    end
  end
end
