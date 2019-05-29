class Api::Current::UsersController < APIController
  skip_before_action :authenticate, only: [:register, :find, :request_otp]
  skip_before_action :validate_facility, only: [:register, :find, :request_otp]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:register, :find, :request_otp]
  before_action :validate_registration_payload, only: %i[register]

  def register
    if FeatureToggle.enabled?('MASTER_USER_AUTHENTICATION')
      result = MasterUser.build_with_phone_number_authentication(user_from_request)
      user = result[:master_user]
      phone_number_authentication = result[:phone_number_authentication]
      registration_facility = phone_number_authentication.facility
      return head :not_found unless registration_facility.present?
      return render json: { errors: user.errors }, status: :bad_request if (user.invalid? || phone_number_authentication.invalid?)
      send_approval_notification_email(user)
    else
      user = User.new(user_from_request)
      return head :not_found unless user.facility.present?
      return render json: { errors: user.errors }, status: :bad_request if user.invalid?
      send_approval_notification_email(user)
    end

    render json: {
      user: user_to_response(user),
      access_token: user.access_token
    }, status: :ok
  end

  def send_approval_notification_email(user)
    if FeatureToggle.auto_approve_for_qa?
      user.sync_approval_allowed
      user.save
    else
      user.sync_approval_requested(I18n.t('registration'))
      user.save
      ApprovalNotifierMailer.with(user: user).registration_approval_email.deliver_later
    end
  end

  def find
    return head :bad_request unless find_params.present?
    if FeatureToggle.enabled?('MASTER_USER_AUTHENTICATION')
      user = find_master_user(find_params)
    else
      user = User.find_by(find_params)
    end
    return head :not_found unless user.present?
    render json: user_to_response(user), status: 200
  end

  def request_otp
    user = MasterUser.find(request_user_id)
    phone_number_authentication = user.phone_number_authentication
    phone_number_authentication.set_otp
    phone_number_authentication.save

    SmsNotificationService
      .new(user.phone_number)
      .send_request_otp_sms(user.otp) unless FeatureToggle.auto_approve_for_qa?

    head :ok
  end

  def reset_password
    current_user.reset_phone_number_authentication_password!(reset_password_digest)
    ApprovalNotifierMailer.with(user: current_user).reset_password_approval_email.deliver_later
    render json: {
      user: user_to_response(current_user),
      access_token: current_user.access_token
    }, status: :ok
  end

  private

  def find_master_user(params)
    if params[:id].present?
      MasterUser.find_by(id: find_params[:id])
    elsif params[:phone_number].present?
      phone_number_authentication = PhoneNumberAuthentication.find_by(phone_number: params[:phone_number])
      phone_number_authentication.master_user if phone_number_authentication.present?
    end
  end

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
