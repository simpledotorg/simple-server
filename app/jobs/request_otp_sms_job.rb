class RequestOtpSmsJob < ApplicationJob
  sidekiq_options queue: :high

  def perform(user)
    context = {
      calling_class: self.class.name,
      user_id: user.id,
      communication_type: :sms
    }

    handle_twilio_errors(user) do
      Messaging::Twilio::Sms.new.send(recipient_number: user.localized_phone_number, message: otp_message(user))
    end
  end

  private

  def otp_message(user)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    I18n.t("communications.request_otp", otp: user.otp, app_signature: app_signature)
  end

  def handle_twilio_errors(user, &block)
    block.call
  rescue TwilioApiService::Error => error
    if error.reason == :invalid_phone_number
      Rails.logger.warn("OTP to #{user.id} failed because of an invalid phone number")
      Statsd.instance.increment("twilio.errors.invalid_phone_number")
      false
    else
      raise error
    end
  end
end
