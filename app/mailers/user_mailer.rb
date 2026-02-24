class UserMailer < ApplicationMailer
  def welcome_employee(user, tenant, temporary_password)
    @user = user
    @tenant = tenant
    @temporary_password = temporary_password
    @login_url = new_user_session_url

    mail(
      to: @user.email,
      subject: "Bienvenido/a a #{@tenant.name} — tus credenciales de acceso"
    )
  end
end
