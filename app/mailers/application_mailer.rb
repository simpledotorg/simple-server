# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAILERS_FROM"].presence || "help@simple.org"
  layout "mailer"

  helper SimpleServerEnvHelper
end
