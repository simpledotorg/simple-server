class Api::V4::PatientController < APIController
  skip_before_action :current_user_present?
  skip_before_action :validate_sync_approval_status_allowed
  skip_before_action :validate_facility
  skip_before_action :validate_current_facility_belongs_to_users_facility_group

  before_action :validate_current_patient
  before_action :authenticate, except: [:request_otp, :activate]

  DEFAULT_USER_OTP_DELAY_IN_SECONDS = 5

  def request_otp
    passport = PatientBusinessIdentifier.find_by(
      identifier: passport_id,
      identifier_type: "simple_bp_passport"
    )
    patient  = passport&.patient
    return head :not_found unless patient.present? && patient.latest_mobile_number.present?

    authentication = PassportAuthentication.find_or_create_by!(
      patient: patient,
      patient_business_identifier: passport
    )

    unless authentication.otp_valid?
      authentication.reset_otp
      authentication.save!
    end

    unless FeatureToggle.enabled?('FIXED_OTP_ON_REQUEST_FOR_QA')
      SendPatientOtpSmsJob.set(wait: otp_delay_seconds).perform_later(authentication)
    end

    head :ok
  end

  def activate
    passport = PatientBusinessIdentifier.find_by(
      identifier: passport_id,
      identifier_type: "simple_bp_passport"
    )
    patient  = passport&.patient
    return head :unauthorized unless patient.present?

    authentication = PassportAuthentication.find_by!(patient_business_identifier: passport)

    if authentication.validate_otp(otp)
      render json: access_token_response(authentication), status: :ok
    else
      return head :unauthorized
    end
  end

  def show
    head :ok
  end

  private

  def passport_id
    params.require(:passport_id)
  end

  def otp
    params.require(:otp)
  end

  def access_token_authorized?
    authenticate_with_http_token do |token, _options|
      current_patient.access_tokens.any? do |patient_token|
        ActiveSupport::SecurityUtils.secure_compare(token, patient_token)
      end
    end
  end

  def access_token_response(authentication)
    {
      access_token: authentication.access_token,
      patient_id: authentication.patient.id
    }
  end

  def authenticate
    return head :unauthorized unless access_token_authorized?
  end

  def current_patient
    @current_patient ||= Patient.find_by(id: request.headers['HTTP_X_PATIENT_ID'])
  end

  def validate_current_patient
    return head :unauthorized unless current_patient.present?
  end

  def otp_delay_seconds
    (ENV['USER_OTP_SMS_DELAY_IN_SECONDS'] || DEFAULT_USER_OTP_DELAY_IN_SECONDS).to_i.seconds
  end
end
