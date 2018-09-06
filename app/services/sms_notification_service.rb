class SmsNotificationService

  def initialize(user)
    @user = user
    @client = Twilio::REST::Client.new
  end

  def notify
    send_sms(I18n.t('sms.notification', otp: user.otp))
  end

  def send_request_otp_sms
    app_signature = Config.get('SIMPLE_APP_SIGNATURE')
    send_sms(I18n.t('sms.request_otp', otp: user.otp, app_signature: app_signature))
  end

  private

  attr_reader :user, :client

  def send_sms(body)
    unless FeatureToggle.enabled?('SMS_NOTIFICATION_FOR_OTP')
      Rails.logger.info "SMS_NOTIFICATION_FOR_OTP Feature is disabled. Skipping SMS notification to user #{user.id}"
      return
    end

    client.messages.create(
      from: Config.get('TWILIO_PHONE_NUMBER'),
      to: user.phone_number.prepend(I18n.t('sms.country_code')),
      body: body
    )
  end
end