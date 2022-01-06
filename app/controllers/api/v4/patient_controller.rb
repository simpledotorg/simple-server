# frozen_string_literal: true

class Api::V4::PatientController < PatientAPIController
  skip_before_action :validate_current_patient, only: [:activate, :login]
  skip_before_action :authenticate, only: [:activate, :login]

  def activate
    passport = PatientBusinessIdentifier.find_by(
      identifier: passport_id,
      identifier_type: "simple_bp_passport"
    )
    patient = passport&.patient
    return head :not_found unless patient.present? && patient.latest_mobile_number.present?

    authentication = PassportAuthentication.find_or_create_by!(patient_business_identifier: passport)

    unless authentication.otp_valid?
      authentication.reset_otp
      authentication.save!
    end

    unless Flipper.enabled?(:fixed_otp)
      SendPatientOtpSmsJob.perform_later(authentication)
    end

    head :ok
  end

  def login
    passport = PatientBusinessIdentifier.find_by(
      identifier: passport_id,
      identifier_type: "simple_bp_passport"
    )
    patient = passport&.patient
    return head :unauthorized unless patient.present?

    authentication = PassportAuthentication.find_by!(patient_business_identifier: passport)

    if authentication.validate_otp(otp)
      render json: access_token_response(authentication), status: :ok
    else
      head :unauthorized
    end
  end

  def show
  end

  private

  def passport_id
    params.require(:passport_id)
  end

  def otp
    params.require(:otp)
  end

  def access_token_response(authentication)
    {
      patient: {
        id: authentication.patient.id,
        access_token: authentication.access_token,
        passport: {
          id: authentication.patient_business_identifier.identifier,
          shortcode: authentication.patient_business_identifier.shortcode
        }
      }
    }
  end
end
