class SmsNotificationService
  include SmsHelper
  DEFAULT_LOCALE = :en

  def initialize(recipient_number, client = Twilio::REST::Client.new)
    @recipient_number = Phonelib.parse(recipient_number, ENV.fetch('DEFAULT_COUNTRY')).raw_national
    @client = client
  end

  def send_request_otp_sms(otp)
    app_signature = ENV['SIMPLE_APP_SIGNATURE']
    send_sms(I18n.t('sms.request_otp',
                    otp: otp,
                    app_signature: app_signature))
  end

  def send_reminder_sms(reminder_type, appointment, callback_url, locale = DEFAULT_LOCALE)
    body = I18n.t("sms.appointment_reminders.#{reminder_type}",
                  facility_name: appointment.facility.name,
                  appointment_date: date_in_locale(appointment.scheduled_date, locale),
                  locale: locale)

    send_sms(body, callback_url)
  end

  private

  attr_reader :recipient_number, :client

  def send_sms(body, callback_url = '')
    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: recipient_number.insert(0, I18n.t('sms.country_code')),
      status_callback: callback_url,
      body: body)
  end
end
