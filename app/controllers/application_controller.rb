class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # Tell pundit how to find the current user
  def pundit_user
    current_admin.master_user
  end

  # Send a user to the admins index after sending invitations
  def after_invite_path_for(inviter, invitee)
    admins_path
  end

  # Customize which fields Devise allows for Admins
  # See https://github.com/plataformatec/devise/tree/v3.5.2#strong-parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:email, :role])
  end
end
