module Api
  module V1
    module Tenant
      class AlertsController < Api::V1::Tenant::BaseController
        def expirations
          authorize InventoryLot
          expiring = tenant_scope(InventoryLot).available.where(expires_on: Date.current..(Date.current + 2.days)).includes(:product)
          expired = tenant_scope(InventoryLot).where("expires_on < ?", Date.current).where.not(status: :consumed).includes(:product)

          render json: {
            data: {
              expiring: expiring.map { |lot| camelize_hash(lot.as_json(include: :product)) },
              expired: expired.map { |lot| camelize_hash(lot.as_json(include: :product)) }
            },
            requestId: request.request_id
          }, status: :ok
        end
      end
    end
  end
end
