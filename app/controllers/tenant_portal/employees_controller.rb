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
        @user.must_change_password = true
        @user.save!
        Membership.create!(
          user: @user,
          tenant: current_tenant,
          role: params.dig(:membership, :role).presence || "tenant_staff",
          active: true
        )
      end

      begin
        UserMailer.welcome_employee(@user, current_tenant, generated_password).deliver_now
        redirect_to tenant_employees_path, notice: "Empleado creado. Se ha enviado un email con las credenciales a #{@user.email}."
      rescue StandardError => e
        Rails.logger.error "Error enviando email de bienvenida: #{e.message}"
        error_detail = Rails.env.development? ? " [#{e.class}: #{e.message}]" : ""
        redirect_to tenant_employees_path, alert: "Empleado creado pero el email falló.#{error_detail} Contraseña temporal: #{generated_password}"
      end
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def update
      @membership.update!(role: params.dig(:membership, :role))
      redirect_to tenant_employees_path, notice: "Rol actualizado"
    rescue ActiveRecord::RecordInvalid
      redirect_to tenant_employees_path, alert: "No se pudo actualizar el empleado"
    end

    def destroy
      if @membership.user == current_user
        return redirect_to tenant_employees_path, alert: "No puedes eliminarte a ti mismo"
      end

      user = @membership.user
      @membership.destroy!
      user.destroy! if user.memberships.reload.empty?
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
