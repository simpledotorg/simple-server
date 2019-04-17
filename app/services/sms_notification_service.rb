class SmsNotificationService
  DEFAULT_LOCALE = :en

  def initialize(recipient_number, client = Twilio::REST::Client.new)
    @recipient_number = Phonelib.parse(recipient_number, ENV.fetch(['DEFAULT_COUNTRY'])).raw_national
    @client = client
  end

  def send_request_otp_sms(otp)
    app_signature = ENV['SIMPLE_APP_SIGNATURE']
    send_sms(I18n.t('sms.request_otp',
                    otp: otp,
                    app_signature: app_signature))
  end

  def send_reminder_sms(facility, appointment, locale = DEFAULT_LOCALE)
    send_sms(I18n.t('sms.overdue_appointment_reminder',
                    facility_name: facility.name,
                    appointment_date: appointment.scheduled_date_for_locale(locale),
                    locale: locale))
  end

  private

  attr_reader :recipient_number, :client

  def send_sms(body)
    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: recipient_number.prepend(I18n.t('sms.country_code')),
      body: body)
  end
end
