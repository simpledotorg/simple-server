class SendPatientOtpSmsJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(passport_authentication)
    phone_number = passport_authentication.patient&.latest_mobile_number
    return unless phone_number.present?

    NotificationService.new.send_sms(phone_number, otp_message(passport_authentication))
  end

  private

  def otp_message(passport_authentication)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    I18n.t("sms.patient_request_otp", otp: passport_authentication.otp, app_signature: app_signature)
  end
end
