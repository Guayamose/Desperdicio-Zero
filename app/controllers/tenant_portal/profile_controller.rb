module TenantPortal
  class ProfileController < TenantPortal::BaseController
    skip_before_action :require_current_tenant!

    def show
    end

    def edit
    end

    def update
      if profile_params[:password].present?
        success = current_user.update(profile_params)
      else
        success = current_user.update(profile_params.except(:password, :password_confirmation, :current_password))
      end

      if success
        bypass_sign_in(current_user)
        redirect_to tenant_profile_path, notice: "Perfil actualizado correctamente."
      else
        flash.now[:alert] = current_user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:full_name, :password, :password_confirmation, :current_password)
    end
  end
end
