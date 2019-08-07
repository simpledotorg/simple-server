class Api::Current::LoginsController < APIController
  skip_before_action :current_user_present?, only: [:login_user]
  skip_before_action :validate_sync_approval_status_allowed, only: [:login_user]
  skip_before_action :authenticate, only: [:login_user]
  skip_before_action :validate_facility, only: [:login_user]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:login_user]
  before_action :validate_login_payload, only: %i[create]

  def login_user
    authentication = PhoneNumberAuthentication.find_by(phone_number: login_params[:phone_number])
    errors = errors_in_user_login(authentication)

    if errors.present?
      render json: { errors: errors }, status: :unauthorized
    else
      user = authentication.user
      authentication.set_access_token
      authentication.save
      AuditLog.login_log(user)
      render json: {
        user: user_to_response(user),
        access_token: user.access_token
      }, status: :ok
    end
  end

  private

  def user_to_response(user)
    Api::Current::UserTransformer.to_response(user)
  end

  def validate_login_payload
    validator = Api::Current::UserLoginPayloadValidator.new(login_params)
    logger.debug "User login params had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      render json: { errors: validator.errors }, status: :unauthorized
    end
  end

  def login_params
    params.require(:user).permit(:phone_number, :password, :otp)
  end

  def errors_in_user_login(user)
    error_string = if !user.present?
      I18n.t('login.error_messages.unknown_user')
    elsif user.otp != login_params[:otp]
      I18n.t('login.error_messages.invalid_otp')
    elsif !user.otp_valid?
      I18n.t('login.error_messages.expired_otp')
    elsif !user.authenticate(login_params[:password])
      I18n.t('login.error_messages.invalid_password')
    end

    if error_string.present?
      Raven.capture_message(
        'Login Error',
        logger: 'logger',
        extra: {
          login_params: login_params,
          errors: error_string
        },
        tags: { type: 'login' }
      )
      { user: [error_string] } if error_string.present?
    end
  end
end
