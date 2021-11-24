class RequestOtpSmsJob < ApplicationJob
  def perform(user)
    context = {
      calling_class: self.class.name,
      user_id: user.id,
      communication_type: :sms
    }
    TwilioApiService.new.send_sms(recipient_number: user.localized_phone_number, message: otp_message(user), context: context)
  end

  private

  def otp_message(user)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    I18n.t("communications.request_otp", otp: user.otp, app_signature: app_signature)
  end
end
