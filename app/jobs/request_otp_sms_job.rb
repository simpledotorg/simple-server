class RequestOtpSmsJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(user)
    SmsNotificationService
      .new(user.phone_number, ENV['TWILIO_PHONE_NUMBER'])
      .send_request_otp_sms(user.otp)
  end
end
