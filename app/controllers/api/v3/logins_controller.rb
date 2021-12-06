class Api::V3::LoginsController < APIController
  skip_before_action :current_user_present?, only: [:login_user]
  skip_before_action :validate_sync_approval_status_allowed, only: [:login_user]
  skip_before_action :authenticate, only: [:login_user]
  skip_before_action :validate_facility, only: [:login_user]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:login_user]
  before_action :validate_login_payload, only: %i[create]

  def login_user
    result = PhoneNumberAuthentication::Authenticate.call(otp: login_params[:otp],
                                                          password: login_params[:password],
                                                          phone_number: login_params[:phone_number])

    if result.success?
      user = result.user
      AuditLog.login_log(user)
      response = {
        user: user_to_response(user),
        access_token: user.access_token
      }
      render json: response, status: :ok
    else
      log_failure(result)
      render json: get_error_response(result), status: :unauthorized
    end
  end

  private

  def get_error_response(result)
    response = {
      errors: {
        user: [result.error_message]
      }
    }
    if result.authentication.in_lockout_period?
      response.merge(remaining_lockout_duration_in_seconds: result.authentication.seconds_left_on_lockout)
    else
      response
    end
  end

  def user_to_response(user)
    Api::V3::UserTransformer.to_response(user)
  end

  def validate_login_payload
    validator = Api::V3::UserLoginPayloadValidator.new(login_params)
    logger.debug "User login params had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      render json: {errors: validator.errors}, status: :unauthorized
    end
  end

  def login_params
    params.require(:user).permit(:phone_number, :password, :otp)
  end

  def log_failure(result)
    Rails.logger.info(
      msg: "login_error",
      controller: self.class.name,
      action: action_name,
      user_id: result.authentication&.user&.id,
      error: result.error_message
    )
  end
end
