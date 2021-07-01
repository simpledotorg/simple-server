class RequestOtpSmsJob < ApplicationJob
  def perform(user)
    TwilioApiService.new.send_sms(user.phone_number, otp_message(user))
  end

  private

  def otp_message(user)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    I18n.t("communications.request_otp", otp: user.otp, app_signature: app_signature)
  end
end
