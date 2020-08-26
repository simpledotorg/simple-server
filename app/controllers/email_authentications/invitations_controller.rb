class EmailAuthentications::InvitationsController < Devise::InvitationsController
  before_action :verify_params, only: [:create]
  before_action :🆕verify_params, only: [:🆕create]
  helper_method :current_admin

  def new
    authorize([:manage, :admin, current_admin])
    super
  end

  def 🆕new
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      raise UserAccess::NotAuthorizedError unless current_admin.can?(:manage, :facility)
      Devise::InvitationsController.instance_method(:new).bind(self).call
    end
  end

  def create
    user = User.new(user_params)
    authorize([:manage, :admin, user])

    User.transaction do
      super do |resource|
        user.email_authentications = [resource]
        user.save!

        next if permission_params.blank?

        permission_params.each do |attributes|
          user.user_permissions.create!(attributes.permit(
            :permission_slug,
            :resource_id,
            :resource_type
          ))
        end
      end
    end
  end

  def 🆕create
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      raise UserAccess::NotAuthorizedError unless current_admin.can?(:manage, :facility)
      🆕verify_params

      User.transaction do
        new_user = User.new(user_params)
        Devise::InvitationsController.instance_method(:create).bind(self).call do |resource|
          new_user.email_authentications = [resource]
          new_user.save!

          current_admin.grant_access(new_user, selected_facilities)
        end
      end
    end
  end

  protected

  def verify_params
    user = User.new(user_params)
    email_authentication = user.email_authentications.new(invite_params.merge(password: temporary_password))

    unless user.valid? && email_authentication.valid?
      user.errors.delete(:email_authentications)
      render json: {errors: user.errors.full_messages + email_authentication.errors.full_messages},
        status: :bad_request
    end
  end

  def 🆕verify_params
    user = User.new(user_params)
    email_authentication = user.email_authentications.new(invite_params.merge(password: temporary_password))

    if selected_facilities.blank?
      redirect_to email_authentications_invitation_new_new_path,
        alert: "At least one facility should be selected for access before inviting an Admin." and return
    end

    if user.invalid? || email_authentication.invalid?
      user.errors.delete(:email_authentications)
      redirect_to email_authentications_invitation_new_new_path,
        alert: user.errors.full_messages + email_authentication.errors.full_messages
    end
  end

  def current_admin
    AdminAccessPresenter.new(current_inviter.user)
  end

  def pundit_user
    current_admin
  end

  def user_params
    {
      full_name: params[:full_name],
      role: params[:role],
      access_level: params[:access_level],
      organization_id: params[:organization_id],
      device_created_at: Time.current,
      device_updated_at: Time.current,
      sync_approval_status: :denied,
    }
  end

  def selected_facilities
    params[:selected_facilities]
  end

  def permission_params
    params[:permissions]
  end

  def invite_params
    {email: params[:email]}
  end

  def temporary_password
    SecureRandom.base64(16)
  end
end
