class SmsNotificationService

  def initialize(user)
    @user = user
    @client = Twilio::REST::Client.new
  end

  def notify
    unless FeatureToggle.enabled?('SMS_NOTIFICATION_FOR_OTP')
      Rails.logger.info "SMS_NOTIFICATION_FOR_OTP Feature is disabled. Skipping SMS notification to user #{user.id}"
      return
    end

    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: user.phone_number.prepend(I18n.t('sms.country_code')),
      body: I18n.t('sms.notification', otp: user.otp)
    )
  end

  private

  attr_reader :user, :client
end