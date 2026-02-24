module TenantPortal
  class PasswordsController < TenantPortal::BaseController
    skip_before_action :require_current_tenant!

    def edit; end

    def update
      if params[:user][:password] != params[:user][:password_confirmation]
        flash.now[:alert] = "Las contraseñas no coinciden"
        return render :edit, status: :unprocessable_entity
      end

      if current_user.update(
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation],
        must_change_password: false
      )
        redirect_to tenant_dashboard_path, notice: "Contraseña actualizada correctamente. ¡Bienvenido/a!"
      else
        flash.now[:alert] = current_user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
