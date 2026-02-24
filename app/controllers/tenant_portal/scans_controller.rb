module TenantPortal
  class ScansController < TenantPortal::BaseController
    def new
      authorize Product
    end

    def create
      authorize Product

      barcode = sanitize_barcode(params.require(:barcode))
      source = params[:source].presence_in(%w[usb camera]) || "usb"
      if barcode.blank?
        redirect_to new_tenant_scan_path, alert: "Debe indicar un codigo de barras valido"
        return
      end

      result = Inventory::BarcodeLookupService.new.call(barcode)
      if result.product.blank?
        redirect_to new_tenant_scan_path, alert: "No se pudo procesar el codigo escaneado"
        return
      end

      AuditLog.create!(
        tenant: current_tenant,
        actor: current_user,
        action: "inventory.scan",
        entity_type: "Product",
        entity_id: result.product.id,
        metadata_json: { barcode: barcode, source: source, lookup_source: result.source }
      )

      if request.format.json?
        render json: { product: result.product.as_json, source: source, lookupSource: result.source, success: result.success }
      else
        prefill = {
          product_id: result.product.id,
          barcode: barcode,
          product_name: result.product.name,
          quantity: 1,
          unit: "unit",
          source: "donation",
          received_on: Date.current,
          expires_on: Date.current + 7.days
        }
        if result.source == "manual_fallback"
          redirect_to new_tenant_inventory_lot_path(inventory_lot: prefill), alert: "El alimento no existe en nuestra base de datos. Completa y guarda el lote manualmente."
        else
          redirect_to new_tenant_inventory_lot_path(inventory_lot: prefill), notice: "Producto listo: #{result.product.name}. Completa y guarda el lote."
        end
      end
    rescue ActionController::ParameterMissing
      redirect_to new_tenant_scan_path, alert: "Debe indicar el codigo de barras"
    end

    private

    def sanitize_barcode(value)
      value.to_s.gsub(/\s+/, "").strip
    end
  end
end
