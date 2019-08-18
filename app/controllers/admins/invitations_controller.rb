class Admins::InvitationsController < Devise::InvitationsController
  before_action :configure_permitted_parameters

  helper_method :current_user

  def new
    authorize :invitation, :new?
    @role = params[:role].downcase.to_sym
    super
  end

  def create
    authorize :invitation, :create?
    @role = params.require(:admin).require(:role).downcase.to_sym
    user = nil
    User.transaction do
      super do |resource|

        # Temporary to make tests work
        user = User.new(full_name: 'test',
                        device_created_at: Time.now,
                        device_updated_at: Time.now,
                        sync_approval_status: :denied)

        user.email_authentications = [resource]
        unless @role == :owner
          admin_access_controls = access_controllable_ids.reject(&:empty?).map do |access_controllable_id|
            AdminAccessControl.new(
              access_controllable_type: access_controllable_type,
              access_controllable_id: access_controllable_id)
          end

          user.admin_access_controls =  admin_access_controls
        end
        user.save!
      end
    end
  end

  protected

  def current_user
    current_admin.user
  end

  def access_controllable_ids
    params.require(:admin).require(:access_controllable_ids)
  end

  def access_controllable_type
    params.require(:admin).require(:access_controllable_type)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite) do |admin_params|
      admin_params.permit({ admin_access_controls: [] }, :email)
    end
  end
end
