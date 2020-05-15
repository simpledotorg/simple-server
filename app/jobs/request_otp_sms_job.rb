class RequestOtpSmsJob < ApplicationJob
  queue_as :default

  def perform(user)
    NotificationService.new.send_sms(user.phone_number, otp_message(user))
  end

  private

  def otp_message(user)
    app_signature = ENV['SIMPLE_APP_SIGNATURE']
    I18n.t("sms.request_otp", otp: user.otp, app_signature: app_signature)
  end
end
