class Api::V4::PatientController < APIController
  skip_before_action :current_user_present?
  skip_before_action :validate_sync_approval_status_allowed
  skip_before_action :authenticate
  skip_before_action :validate_facility
  skip_before_action :validate_current_facility_belongs_to_users_facility_group

  DEFAULT_USER_OTP_DELAY_IN_SECONDS = 5

  def activate
    passport = PatientBusinessIdentifier.find_by(
      identifier: request_passport_id,
      identifier_type: "simple_bp_passport"
    )
    patient  = passport&.patient
    return head :not_found unless patient.present?

    authentication = PassportAuthentication.find_or_create_by!(
      patient: patient,
      patient_business_identifier: passport
    )

    # TODO: Send OTP

    head :ok
  end

  def authenticate
    passport = PatientBusinessIdentifier.find_by(
      identifier: request_passport_id,
      identifier_type: "simple_bp_passport"
    )
    patient  = passport&.patient
    return head :not_found unless patient.present?

    authentication = PassportAuthentication.find_by!(patient_business_identifier: passport)

    if authentication.otp == request_otp && authentication.otp_valid?
      render json: access_token_response(authentication), status: :ok
    else
      return head :unauthorized
    end
  end

  private

  def request_passport_id
    params.require(:passport_id)
  end

  def request_otp
    params.require(:otp)
  end

  def access_token_response(authentication)
    { access_token: authentication.access_token }
  end
end
