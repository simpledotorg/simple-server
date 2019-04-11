class SmsNotificationService
  DEFAULT_LOCALE = :en

  def initialize(user, client = Twilio::REST::Client.new)
    @user = user
    @client = client
  end

  def notify
    send_sms(I18n.t('sms.notification', otp: user.otp))
  end

  def send_request_otp_sms
    app_signature = ENV['SIMPLE_APP_SIGNATURE']
    send_sms(I18n.t('sms.request_otp', otp: user.otp, app_signature: app_signature))
  end

  def send_reminder_sms(facility, appointment, locale = DEFAULT_LOCALE)
    send_sms(I18n.t('sms.overdue_appointment_reminder',
                    facility_name: facility.name,
                    appointment_date: appointment.scheduled_date_for_locale(locale),
                    locale: locale))
  end

  private

  attr_reader :user, :client

  def send_sms(body)
    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: user.phone_number.prepend(I18n.t('sms.country_code')),
      body: body)
  end
end
