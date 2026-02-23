module Admin
  class TenantsController < Admin::BaseController
    before_action :set_tenant, only: [ :show, :edit, :update, :destroy ]

    def index
      @tenants = policy_scope(Tenant).order(:name)
      authorize Tenant
    end

    def show
      authorize @tenant
    end

    def new
      @tenant = Tenant.new
      authorize @tenant
    end

    def create
      @tenant = Tenant.new(tenant_params)
      authorize @tenant

      if @tenant.save
        AuditLogger.log!(action: "admin.tenant.created", actor: current_user, tenant: nil, entity: @tenant, metadata: {}, ip_address: request.remote_ip)
        redirect_to admin_tenant_path(@tenant), notice: "Comedor creado"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @tenant
    end

    def update
      authorize @tenant

      if @tenant.update(tenant_params)
        AuditLogger.log!(action: "admin.tenant.updated", actor: current_user, tenant: nil, entity: @tenant, metadata: {}, ip_address: request.remote_ip)
        redirect_to admin_tenant_path(@tenant), notice: "Comedor actualizado"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @tenant
      @tenant.destroy!
      redirect_to admin_tenants_path, notice: "Comedor eliminado"
    end

    private

    def set_tenant
      @tenant = Tenant.find(params[:id])
    end

    def tenant_params
      params.require(:tenant).permit(:name, :slug, :status, :address, :city, :region, :country, :latitude, :longitude, :contact_email, :contact_phone, operating_hours_json: {})
    end
  end
end
