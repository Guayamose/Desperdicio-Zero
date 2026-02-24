module TenantPortal
  class InventoryLotsController < TenantPortal::BaseController
    before_action :set_inventory_lot, only: [ :show, :edit, :update, :destroy ]

    def index
      @inventory_lots = tenant_scope(InventoryLot).includes(:product).order(expires_on: :asc)
      authorize InventoryLot
    end

    def show
      authorize @inventory_lot
    end

    def new
      @inventory_lot = current_tenant.inventory_lots.new(received_on: Date.current)
      apply_prefill_to_new_lot(@inventory_lot)
      prepare_form_state
      authorize @inventory_lot
    end

    def create
      @inventory_lot = current_tenant.inventory_lots.new(inventory_lot_params.except(:barcode, :product_name, :unknown_barcode_confirmed))
      authorize @inventory_lot

      if unknown_barcode_requires_confirmation?
        @inventory_lot.errors.add(:base, unknown_barcode_confirmation_message)
        prepare_form_state
        render :new, status: :unprocessable_entity
        return
      end

      @inventory_lot.product = resolve_product

      if @inventory_lot.save
        create_stock_movement!(@inventory_lot, :inbound, @inventory_lot.quantity, "initial_stock")
        AuditLogger.log!(action: "inventory_lot.created", actor: current_user, tenant: current_tenant, entity: @inventory_lot, metadata: { product_id: @inventory_lot.product_id }, ip_address: request.remote_ip)
        redirect_to tenant_inventory_lot_path(@inventory_lot), notice: "Lote creado"
      else
        prepare_form_state
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      prepare_form_state
      authorize @inventory_lot
    end

    def update
      authorize @inventory_lot
      previous_quantity = @inventory_lot.quantity

      @inventory_lot.assign_attributes(inventory_lot_params.except(:barcode, :product_name, :unknown_barcode_confirmed))

      if unknown_barcode_requires_confirmation?
        @inventory_lot.errors.add(:base, unknown_barcode_confirmation_message)
        prepare_form_state
        render :edit, status: :unprocessable_entity
        return
      end

      @inventory_lot.product = resolve_product if inventory_lot_params[:barcode].present? || inventory_lot_params[:product_name].present? || inventory_lot_params[:product_id].present?

      if @inventory_lot.save
        delta = @inventory_lot.quantity - previous_quantity
        create_stock_movement!(@inventory_lot, :adjustment, delta, "manual_update") unless delta.zero?
        AuditLogger.log!(action: "inventory_lot.updated", actor: current_user, tenant: current_tenant, entity: @inventory_lot, metadata: { quantity_delta: delta }, ip_address: request.remote_ip)
        redirect_to tenant_inventory_lot_path(@inventory_lot), notice: "Lote actualizado"
      else
        prepare_form_state
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @inventory_lot

      create_stock_movement!(@inventory_lot, :waste, -@inventory_lot.quantity, "deleted_lot")
      @inventory_lot.destroy!
      redirect_to tenant_inventory_lots_path, notice: "Lote eliminado"
    end

    private

    def set_inventory_lot
      @inventory_lot = tenant_scope(InventoryLot).find(params[:id])
    end

    def inventory_lot_params
      params.require(:inventory_lot).permit(:product_id, :barcode, :product_name, :unknown_barcode_confirmed, :expires_on, :quantity, :unit, :status, :received_on, :source, :notes)
    end

    def raw_inventory_lot_params
      return ActionController::Parameters.new unless params[:inventory_lot].present?

      params[:inventory_lot].permit(:product_id, :barcode, :product_name, :unknown_barcode_confirmed, :expires_on, :quantity, :unit, :status, :received_on, :source, :notes)
    end

    def apply_prefill_to_new_lot(lot)
      prefill = raw_inventory_lot_params
      return if prefill.blank?

      lot.assign_attributes(prefill.except(:product_id, :barcode, :product_name, :unknown_barcode_confirmed))
      lot.product = Product.find_by(id: prefill[:product_id]) if prefill[:product_id].present?
    end

    def prepare_form_state
      prefill = raw_inventory_lot_params
      @prefill_barcode = prefill[:barcode].presence
      @prefill_product_name = prefill[:product_name].presence

      selected_product_id = prefill[:product_id].presence || @inventory_lot&.product_id
      @selected_product = Product.find_by(id: selected_product_id) if selected_product_id.present?
      @selected_product ||= @inventory_lot&.product
    end

    def resolve_product
      if inventory_lot_params[:product_id].present?
        product = Product.find(inventory_lot_params[:product_id])
        apply_manual_name!(product)
        return product
      end

      if inventory_lot_params[:barcode].present?
        result = Inventory::BarcodeLookupService.new.call(inventory_lot_params[:barcode])
        product = result.product
        apply_manual_name!(product)
        return product if product.present?
      end

      Product.create!(
        name: inventory_lot_params[:product_name].presence || "Producto manual",
        barcode: inventory_lot_params[:barcode].presence,
        source: :manual
      )
    end

    def apply_manual_name!(product)
      return if product.blank?

      manual_name = inventory_lot_params[:product_name].to_s.strip
      return if manual_name.blank?
      return if product.name == manual_name

      product.update!(name: manual_name)
    end

    def create_stock_movement!(lot, movement_type, quantity_delta, reason)
      StockMovement.create!(
        tenant: current_tenant,
        inventory_lot: lot,
        movement_type: movement_type,
        quantity_delta: quantity_delta,
        reason: reason,
        performed_by: current_user,
        occurred_at: Time.current
      )
    end

    def unknown_barcode_requires_confirmation?
      barcode = sanitize_barcode(inventory_lot_params[:barcode])
      return false if barcode.blank? || barcode.length < 6
      return false if unknown_barcode_confirmed?
      return false if unchanged_inventory_lot_barcode?(barcode)

      Integrations::OpenFoodFactsClient.new.fetch_product(barcode).blank?
    rescue StandardError
      true
    end

    def sanitize_barcode(value)
      value.to_s.gsub(/\s+/, "").strip
    end

    def unknown_barcode_confirmed?
      ActiveModel::Type::Boolean.new.cast(inventory_lot_params[:unknown_barcode_confirmed])
    end

    def unchanged_inventory_lot_barcode?(barcode)
      return false unless @inventory_lot&.persisted?

      @inventory_lot.product&.barcode.to_s == barcode
    end

    def unknown_barcode_confirmation_message
      "El codigo de barras no existe en OpenFoodFacts. Confirma que quieres guardar este alimento manualmente."
    end
  end
end
