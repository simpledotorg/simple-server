class EmailAuthentications::InvitationsController < Devise::InvitationsController
  before_action :verify_params, only: [:create], unless: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  before_action :🆕verify_params, only: [:create], if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  helper_method :current_admin

  def new
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      raise UserAccess::NotAuthorizedError unless current_admin.accessible_facilities(:manage).any?
    else
      authorize([:manage, :admin, current_admin])
    end

    super
  end

  def create
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      raise UserAccess::NotAuthorizedError unless current_admin.accessible_facilities(:manage).any?
      
      User.transaction do
        new_user = User.new(user_params)

        super do |resource|
          new_user.email_authentications = [resource]
          new_user.save!

          current_admin.grant_access(new_user, selected_facilities)
        end
      end
    else
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
  end

  protected

  def verify_params
    user = User.new(user_params)
    email_authentication = user.email_authentications.new(invite_params.merge(password: temporary_password))

    unless user.valid? && email_authentication.valid?
      user.errors.delete(:email_authentications)
      render json: {errors: user.errors.full_messages + email_authentication.errors.full_messages}, status: :bad_request
    end
  end

  #
  # This is a temporary `verify_params` method that will exist until we migrate fully to the new permissions system
  #
  def 🆕verify_params
    user = User.new(user_params)
    email_authentication = user.email_authentications.new(invite_params.merge(password: temporary_password))

    if selected_facilities.blank?
      redirect_to new_email_authentication_invitation_path,
        alert: "At least one facility should be selected for access before inviting an Admin." && return
    end

    if user.invalid? || email_authentication.invalid?
      user.errors.delete(:email_authentications)
      redirect_to new_email_authentication_invitation_path,
        alert: (user.errors.full_messages + email_authentication.errors.full_messages).join("\n")
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
      sync_approval_status: :denied
    }
  end

  def selected_facilities
    params[:facilities]
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
