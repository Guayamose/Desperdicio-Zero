class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "no-reply@desperdicio-zero.com")
  layout "mailer"
end
