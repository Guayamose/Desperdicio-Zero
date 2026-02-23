module TenantPortal
  class EmployeesController < TenantPortal::BaseController
    before_action :require_tenant_manager!
    before_action :set_membership, only: [ :update, :destroy ]

    def index
      @memberships = current_tenant.memberships.includes(:user).order(created_at: :desc)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      generated_password = Devise.friendly_token.first(12)
      @user.password = generated_password
      @user.password_confirmation = generated_password

      ActiveRecord::Base.transaction do
        @user.save!
        Membership.create!(
          user: @user,
          tenant: current_tenant,
          role: params.dig(:membership, :role).presence || "tenant_staff",
          active: true
        )
      end

      redirect_to tenant_employees_path, notice: "Empleado creado. Contraseña temporal: #{generated_password}"
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def update
      new_role = params.dig(:membership, :role)
      new_active = params.dig(:membership, :active)

      if new_role.present?
        @membership.update!(role: new_role)
      elsif new_active.present?
        @membership.update!(active: new_active == "true")
      end

      redirect_to tenant_employees_path, notice: "Empleado actualizado"
    rescue ActiveRecord::RecordInvalid
      redirect_to tenant_employees_path, alert: "No se pudo actualizar el empleado"
    end

    def destroy
      if @membership.user == current_user
        return redirect_to tenant_employees_path, alert: "No puedes eliminarte a ti mismo"
      end

      @membership.destroy!
      redirect_to tenant_employees_path, notice: "Empleado eliminado del comedor"
    end

    private

    def set_membership
      @membership = current_tenant.memberships.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:full_name, :email)
    end
  end
end
