class Admins::InvitationsController < Devise::InvitationsController
  before_action :configure_permitted_parameters

  def new
    authorize :invitation, :new?
    super
  end

  def create
    authorize :invitation, :create?
    super do |email_authentication|
      return redirect_to admin_new_user_for_invite_path(email_authentication_id: email_authentication.id)
    end
  end

  protected

  def access_controllable_ids
    params.require(:admin).require(:access_controllable_ids)
  end

  def access_controllable_type
    params.require(:admin).require(:access_controllable_type)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite) do |admin_params|
      admin_params.permit({ admin_access_controls: [] }, :role, :email)
    end
  end
end
