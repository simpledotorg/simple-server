class Admins::InvitationsController < Devise::InvitationsController
  before_action :configure_permitted_parameters

  helper_method :current_user, :selectable_resource_types, :resource_type_and_id

  def new
    authorize :invitation, :new?
    @role = params[:role].downcase.to_sym
    super
  end

  def create
    authorize :invitation, :create?
    @role = params.require(:admin).require(:role).downcase.to_sym
    User.transaction do
      super do |resource|
        user = User.new(user_params)
        user.email_authentications = [resource]
        user.save!
        resources_by_type = user.resources.group_by { |r| r.class.to_s}
        user.assign_default_permissions!(resources_by_type)
      end
    end
  end

  protected

  def current_user
    current_admin.user
  end

  def selectable_resource_types
    User::DEFAULT_PERMISSIONS[@role]
      .map { |permission_slug| Permissions::ALL_PERMISSIONS[permission_slug][:resource_type] }
      .uniq
  end

  def user_params
    params.require(:admin)
      .permit(:full_name, :role, resources: [])
      .merge(device_created_at: Time.now,
             device_updated_at: Time.now,
             sync_approval_status: :denied)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite) do |admin_params|
      admin_params.permit({ admin_access_controls: [] }, :email)
    end
  end
end
