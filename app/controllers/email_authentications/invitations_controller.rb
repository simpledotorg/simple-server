class EmailAuthentications::InvitationsController < Devise::InvitationsController
  helper_method :current_admin

  def new
    authorize([:manage, :admin, current_admin])
    super
  end

  def create
    user = User.new(user_params)
    authorize([:manage, :admin, user])

    existing_email = EmailAuthentication.find_by(invite_params)
    if existing_email.present?
      return render json: { errors: ['Email already invited'] }, status: :bad_request
    end

    User.transaction do
      super do |resource|
        errors = []

        errors.append(resource.errors.full_messages) if resource.invalid?
        errors.append(user_param_errors)

        return render json: { errors: errors.flatten },
                      status: :bad_request if errors.present?

        user.email_authentications = [resource]
        user.save!

        next if permission_params.blank?

        permission_params.each do |attributes|
          user.user_permissions.create!(attributes.permit(
            :permission_slug,
            :resource_id,
            :resource_type))
        end
      end
    end
  end

  protected

  def user_param_errors
    user = User.new(user_params)
    return user.errors.full_messages if user.invalid?

    []
  end

  def current_admin
    current_inviter.user
  end

  def pundit_user
    current_admin
  end

  def user_params
    { full_name: params[:full_name],
      role: params[:role],
      organization_id: params[:organization_id],
      device_created_at: Time.current,
      device_updated_at: Time.current,
      sync_approval_status: :denied }
  end

  def permission_params
    params[:permissions]
  end

  def invite_params
    email = params[:email]


    { email: email }
  end
end
