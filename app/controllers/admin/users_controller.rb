module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [ :show, :block, :anonymize, :export ]

    def index
      @users = policy_scope(User).order(created_at: :desc)
      authorize User
    end

    def show
      authorize @user
    end

    def new
      @user = User.new
      authorize @user
      @tenants = Tenant.order(:name)
    end

    def create
      @user = User.new(user_params)
      authorize @user
      @tenants = Tenant.order(:name)

      generated_password = Devise.friendly_token.first(12)
      @user.password = generated_password
      @user.password_confirmation = generated_password

      ActiveRecord::Base.transaction do
        @user.save!

        if params.dig(:membership, :tenant_id).present?
          Membership.create!(
            user: @user,
            tenant_id: params.dig(:membership, :tenant_id),
            role: params.dig(:membership, :role) || "tenant_staff",
            active: true
          )
        end

        if params[:system_admin] == "1"
          SystemRole.find_or_create_by!(user: @user, role: :system_admin)
        end
      end

      AuditLogger.log!(action: "admin.user.created", actor: current_user, tenant: nil, entity: @user, metadata: { tenant_id: params.dig(:membership, :tenant_id) }, ip_address: request.remote_ip)
      redirect_to admin_user_path(@user), notice: "Usuario creado. Password temporal: #{generated_password}"
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def block
      authorize @user, :block?
      @user.update!(blocked_at: Time.current)
      AuditLogger.log!(action: "admin.user.blocked", actor: current_user, tenant: nil, entity: @user, metadata: {}, ip_address: request.remote_ip)
      redirect_to admin_user_path(@user), notice: "Usuario bloqueado"
    end

    def anonymize
      authorize @user, :update?
      @user.anonymize_personal_data!
      AuditLogger.log!(action: "admin.user.anonymized", actor: current_user, tenant: nil, entity: @user, metadata: {}, ip_address: request.remote_ip)
      redirect_to admin_user_path(@user), notice: "Datos personales anonimizados"
    end

    def export
      authorize @user

      payload = {
        id: @user.id,
        full_name: @user.full_name,
        email: @user.email,
        locale: @user.locale,
        gdpr_consent_at: @user.gdpr_consent_at,
        blocked_at: @user.blocked_at,
        memberships: @user.memberships.includes(:tenant).map do |membership|
          {
            tenant: membership.tenant.name,
            role: membership.role,
            active: membership.active
          }
        end
      }

      send_data JSON.pretty_generate(payload), filename: "user-#{@user.id}-export.json", type: "application/json"
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:full_name, :email, :locale, :gdpr_consent_at)
    end
  end
end
