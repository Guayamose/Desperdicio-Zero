module Api
  module V1
    module Admin
      class TenantsController < Api::V1::Admin::BaseController
        before_action :set_tenant, only: [ :update, :destroy ]

        def index
          authorize Tenant
          render_collection(policy_scope(Tenant).order(:name))
        end

        def create
          tenant = Tenant.new(tenant_params)
          authorize tenant

          if tenant.save
            render_resource(tenant, status: :created)
          else
            render_error(code: "validation_error", message: "Invalid tenant", details: tenant.errors.full_messages, status: :unprocessable_entity)
          end
        end

        def update
          authorize @tenant

          if @tenant.update(tenant_params)
            render_resource(@tenant)
          else
            render_error(code: "validation_error", message: "Invalid tenant", details: @tenant.errors.full_messages, status: :unprocessable_entity)
          end
        end

        def destroy
          authorize @tenant
          @tenant.destroy!
          render json: { success: true, requestId: request.request_id }, status: :ok
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
  end
end
