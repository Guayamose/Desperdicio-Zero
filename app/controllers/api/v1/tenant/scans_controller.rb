module Api
  module V1
    module Tenant
      class ScansController < Api::V1::Tenant::BaseController
        def create
          authorize Product, :create?

          barcode = sanitize_barcode(params.require(:barcode))
          if barcode.blank?
            render_error(code: "invalid_barcode", message: "Barcode is required", status: :unprocessable_entity)
            return
          end

          source = params[:source].presence_in(%w[usb camera]) || "usb"
          result = Inventory::BarcodeLookupService.new.call(barcode)
          if result.product.blank?
            render_error(code: "lookup_failed", message: "Unable to resolve barcode", details: result.error, status: :unprocessable_entity)
            return
          end

          AuditLog.create!(tenant: current_tenant, actor: current_user, action: "api.inventory.scan", entity_type: "Product", entity_id: result.product.id, metadata_json: { barcode: barcode, source: source, lookupSource: result.source })

          render json: {
            data: {
              product: camelize_hash(result.product.as_json),
              source: source,
              lookupSource: result.source,
              success: result.success
            },
            requestId: request.request_id
          }, status: :ok
        end

        def barcode_check
          authorize Product, :create?

          barcode = sanitize_barcode(params.require(:barcode))
          if barcode.blank? || barcode.length < 6
            render_error(code: "invalid_barcode", message: "Barcode is invalid", status: :unprocessable_content)
            return
          end

          exists = Integrations::OpenFoodFactsClient.new.fetch_product(barcode).present?
          render json: {
            data: {
              barcode: barcode,
              exists: exists
            },
            requestId: request.request_id
          }, status: :ok
        end

        private

        def sanitize_barcode(value)
          value.to_s.gsub(/\s+/, "").strip
        end
      end
    end
  end
end
