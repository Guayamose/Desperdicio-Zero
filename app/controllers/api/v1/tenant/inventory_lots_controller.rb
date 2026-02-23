module Api
  module V1
    module Tenant
      class InventoryLotsController < Api::V1::Tenant::BaseController
        before_action :set_inventory_lot, only: [ :update, :destroy ]

        def index
          authorize InventoryLot
          scoped = tenant_scope(InventoryLot).includes(:product).order(expires_on: :asc)
          lots = paginate(scoped)

          render json: {
            data: lots.map { |lot| camelize_hash(lot.as_json(include: :product)) },
            meta: pagination_meta(scoped),
            requestId: request.request_id
          }, status: :ok
        end

        def create
          lot = current_tenant.inventory_lots.new(inventory_lot_params.except(:barcode, :product_name))
          lot.product = resolve_product
          authorize lot

          if lot.save
            StockMovement.create!(tenant: current_tenant, inventory_lot: lot, movement_type: :inbound, quantity_delta: lot.quantity, reason: "api_create", performed_by: current_user, occurred_at: Time.current)
            render_resource(lot.as_json(include: :product), status: :created)
          else
            render_error(code: "validation_error", message: "Invalid inventory lot", details: lot.errors.full_messages, status: :unprocessable_entity)
          end
        end

        def update
          authorize @inventory_lot

          if @inventory_lot.update(inventory_lot_params.except(:barcode, :product_name))
            render_resource(@inventory_lot.as_json(include: :product))
          else
            render_error(code: "validation_error", message: "Invalid inventory lot", details: @inventory_lot.errors.full_messages, status: :unprocessable_entity)
          end
        end

        def destroy
          authorize @inventory_lot
          @inventory_lot.destroy!
          render json: { success: true, requestId: request.request_id }, status: :ok
        end

        private

        def set_inventory_lot
          @inventory_lot = tenant_scope(InventoryLot).find(params[:id])
        end

        def inventory_lot_params
          params.require(:inventory_lot).permit(:product_id, :barcode, :product_name, :expires_on, :quantity, :unit, :status, :received_on, :source, :notes)
        end

        def resolve_product
          return Product.find(inventory_lot_params[:product_id]) if inventory_lot_params[:product_id].present?

          if inventory_lot_params[:barcode].present?
            result = Inventory::BarcodeLookupService.new.call(inventory_lot_params[:barcode])
            return result.product if result.product.present?
          end

          Product.create!(
            name: inventory_lot_params[:product_name].presence || "Producto manual",
            barcode: inventory_lot_params[:barcode].presence,
            source: :manual
          )
        end
      end
    end
  end
end
