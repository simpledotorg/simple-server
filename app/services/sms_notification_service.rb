class SmsNotificationService

  def initialize(user)
    @user = user
    @client = Twilio::REST::Client.new
  end

  def notify
    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: user.phone_number,
      body: I18n.t('sms.notification', otp: I18n.t(user.otp))
    )
  end

  private

  attr_reader :user, :client
end