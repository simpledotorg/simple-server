class ApplicationMailer < ActionMailer::Base
  default from: "help@simple.org"
  layout "mailer"

  helper SimpleServerEnvHelper
end
