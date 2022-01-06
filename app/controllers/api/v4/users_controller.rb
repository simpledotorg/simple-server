# frozen_string_literal: true

class Api::V4::UsersController < APIController
  skip_before_action :current_user_present?, only: [:find, :activate]
  skip_before_action :validate_sync_approval_status_allowed, only: [:find, :activate, :me]
  skip_before_action :authenticate, only: [:find, :activate]
  skip_before_action :validate_facility, only: [:find, :activate]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:find, :activate]

  DEFAULT_USER_OTP_DELAY_IN_SECONDS = 5

  def find
    return head :bad_request unless params[:phone_number].present?
    user = PhoneNumberAuthentication.find_by(phone_number: params[:phone_number])&.user
    return head :not_found unless user.present?
    render json: to_find_response(user), status: :ok
  end

  def activate
    return head :bad_request unless activate_params.present?

    user = User.find_by(id: activate_params[:id])
    authentication = user&.phone_number_authentication
    errors = login_errors(authentication)

    if errors.present?
      log_failure(user: user, errors: errors)
      render json: {errors: errors}, status: :unauthorized
    else
      authentication.set_otp
      authentication.save

      unless user.feature_enabled?(:fixed_otp)
        delay_seconds = (ENV["USER_OTP_SMS_DELAY_IN_SECONDS"] || DEFAULT_USER_OTP_DELAY_IN_SECONDS).to_i.seconds
        RequestOtpSmsJob.set(wait: delay_seconds).perform_later(user)
      end

      AuditLog.login_log(user)
      render json: to_response(user), status: :ok
    end
  end

  def me
    render json: to_response(current_user), status: :ok
  end

  private

  def activate_params
    params.require(:user).permit(:id, :password)
  end

  def to_find_response(user)
    {user: Api::V4::UserTransformer.to_find_response(user)}
  end

  def to_response(user)
    {"user" => Api::V4::UserTransformer.to_response(user)}
  end

  def login_errors(authentication)
    if authentication.blank? || !authentication.authenticate(activate_params[:password])
      {user: [I18n.t("login.error_messages.invalid_password")]}
    end
  end

  def log_failure(user:, errors:)
    Rails.logger.info(
      msg: "login_error",
      controller: self.class.name,
      action: action_name,
      user_id: user&.id,
      error: errors
    )
  end
end
