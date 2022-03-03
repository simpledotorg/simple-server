class SendPatientOtpSmsJob < ApplicationJob
  def perform(passport_authentication)
    phone_number = passport_authentication.patient&.latest_mobile_number
    return unless phone_number.present?

    Messaging::Twilio::OtpSms.new.send_message(
      recipient_number: phone_number,
      message: otp_message(passport_authentication)
    )
  end

  private

  def otp_message(passport_authentication)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    I18n.t("communications.patient_request_otp", otp: passport_authentication.otp, app_signature: app_signature)
  end
end
