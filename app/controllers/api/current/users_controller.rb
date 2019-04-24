class Api::Current::UsersController < APIController
  skip_before_action :authenticate, only: [:register, :find, :request_otp]
  skip_before_action :validate_facility, only: [:register, :find, :request_otp]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:register, :find, :request_otp]
  before_action :validate_registration_payload, only: %i[register]

  def register
    user = User.new(user_from_request)
    return head :not_found unless user.facility.present?
    return render json: { errors: user.errors }, status: :bad_request if user.invalid?
    if FeatureToggle.auto_approve?
      user.sync_approval_allowed
      user.save
    else
      user.sync_approval_requested(I18n.t('registration'))
      user.save
      ApprovalNotifierMailer.with(user: user).registration_approval_email.deliver_later
    end
    render json: {
      user: user_to_response(user),
      access_token: user.access_token
    }, status: :ok
  end

  def find
    return head :bad_request unless find_params.present?
    user = User.find_by(find_params)
    return head :not_found unless user.present?
    render json: user_to_response(user), status: 200
  end

  def request_otp
    user = User.find(request_user_id)
    user.set_otp
    user.save
    SmsNotificationService.new(user.phone_number).send_request_otp_sms(user.otp)
    head :ok
  end

  def reset_password
    current_user.reset_password(reset_password_digest)
    current_user.save
    ApprovalNotifierMailer.with(user: current_user).reset_password_approval_email.deliver_later
    render json: {
      user: user_to_response(current_user),
      access_token: current_user.access_token
    }, status: :ok
  end

  private

  def user_from_request
    Api::Current::Transformer.from_request(registration_params)
  end

  def user_to_response(user)
    Api::Current::UserTransformer.to_response(user)
  end

  def validate_registration_payload
    validator = Api::Current::UserRegistrationPayloadValidator.new(registration_params)
    logger.debug "User registration params had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      render json: { errors: validator.errors }, status: :bad_request
    end
  end

  def registration_params
    params.require(:user)
      .permit(
        :id,
        :full_name,
        :phone_number,
        :password_digest,
        :updated_at,
        :created_at,
        :registration_facility_id)
  end

  def find_params
    params.permit(:id, :phone_number)
  end

  def request_user_id
    params.require(:id)
  end

  def reset_password_digest
    params.require(:password_digest)
  end
end
