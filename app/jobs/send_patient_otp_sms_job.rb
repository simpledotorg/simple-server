# frozen_string_literal: true

class SendPatientOtpSmsJob < ApplicationJob
  def perform(passport_authentication)
    phone_number = passport_authentication.patient&.latest_mobile_number
    return unless phone_number.present?

    context = {
      calling_class: self.class.name,
      patient_id: passport_authentication.patient&.id,
      communication_type: :sms
    }
    TwilioApiService.new.send_sms(
      recipient_number: phone_number,
      message: otp_message(passport_authentication),
      context: context
    )
  end

  private

  def otp_message(passport_authentication)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    I18n.t("communications.patient_request_otp", otp: passport_authentication.otp, app_signature: app_signature)
  end
end
