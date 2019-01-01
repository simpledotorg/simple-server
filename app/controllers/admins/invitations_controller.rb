class Admins::InvitationsController < Devise::InvitationsController
  before_action :configure_permitted_parameters

  def new
    @role = params[:role].downcase.to_sym
    super
  end

  def create
    @role = params.require(:admin).require(:role).downcase.to_sym
    admin_access_controls = access_controllable_ids.reject(&:empty?).map do |access_controllable_id|
      AdminAccessControl.new(
        access_controllable_type: access_controllable_type,
        access_controllable_id: access_controllable_id)
    end
    invite_resource.admin_access_controls = admin_access_controls
    super
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
