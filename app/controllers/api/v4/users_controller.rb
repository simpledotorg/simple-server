class Api::V4::UsersController < APIController
  skip_before_action :current_user_present?, only: [:activate]
  skip_before_action :validate_sync_approval_status_allowed, only: [:activate, :me]
  skip_before_action :authenticate, only: [:activate]
  skip_before_action :validate_facility, only: [:activate]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:activate]

  def activate
    return head :bad_request unless activate_params.present?

    user = User.find_by(id: activate_params[:id])
    authentication = user&.phone_number_authentication
    errors = errors_in_user_login(authentication)

    if errors.present?
      render json: { errors: errors }, status: :unauthorized
    else
      authentication.set_otp
      authentication.save

      unless FeatureToggle.auto_approve_for_qa?
        SmsNotificationService
          .new(user.phone_number, ENV['TWILIO_PHONE_NUMBER'])
          .send_request_otp_sms(user.otp)
      end

      AuditLog.login_log(user)
      render json: user_to_response(user), status: :ok
    end
  end

  def me
    render json: user_to_response(current_user), status: :ok
  end

  private

  def activate_params
    params.require(:user).permit(:id, :password)
  end

  def user_to_response(user)
    { 'user' => Api::V4::UserTransformer.to_response(user) }
  end

  def errors_in_user_login(user)
    error_string = if user.blank? || !user.authenticate(activate_params[:password])
                     I18n.t('login.error_messages.invalid_password')
                   end

    if error_string.present?
      Raven.capture_message('Login Error',
                            logger: 'logger',
                            extra: { activate_params: activate_params, errors: error_string },
                            tags: { type: 'login' })
      { user: [error_string] }
    end
  end
end
