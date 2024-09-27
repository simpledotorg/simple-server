class RequestOtpSmsJob < ApplicationJob
  queue_as :high

  def perform(user)
    handle_twilio_errors(user) do
      Messaging::Twilio::OtpSms.send_message(
        recipient_number: user.localized_phone_number,
        message: otp_message(user)
      )
    end
  end

  private

  def otp_message(user)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    I18n.t("communications.request_otp", otp: user.otp, app_signature: app_signature)
  end

  def handle_twilio_errors(user, &block)
    block.call
  rescue Messaging::Twilio::Error => error
    if error.reason == :invalid_phone_number
      Rails.logger.warn("OTP to #{user.id} failed because of an invalid phone number")
      Metrics.instance.increment("twilio_invalid_phone_number_errors")
      false
    else
      raise error
    end
  end
end
