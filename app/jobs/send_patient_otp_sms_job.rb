class SendPatientOtpSmsJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(patient_authentication)
    phone_number = patient_authentication.patient&.latest_mobile_number

    return unless phone_number.present?

    SmsNotificationService
      .new(phone_number, ENV['TWILIO_PHONE_NUMBER'])
      .send_request_otp_sms(patient_authentication.otp)
  end
end
