class Admins::InvitationsController < Devise::InvitationsController
  before_action :configure_permitted_parameters
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite) do |admin_params|
      admin_params.permit({ facility_group_ids: [] }, :role, :email)
    end
  end
end
