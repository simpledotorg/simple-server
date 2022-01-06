# frozen_string_literal: true

class EmailAuthentications::PasswordsController < Devise::PasswordsController
  def edit
    users_email_authentication = resource_class.with_reset_password_token(params["reset_password_token"])
    return render "expired_reset_token" unless users_email_authentication&.reset_password_period_valid?
    super
  end
end
