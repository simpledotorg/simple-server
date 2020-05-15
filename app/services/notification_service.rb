class NotificationService
  include Rails.application.routes.url_helpers

  DEFAULT_LOCALE = :en

  attr_reader :client

  def initialize
    @client = Twilio::REST::Client.new(twilio_account_sid, twilio_auth_token)
  end

=begin
  def send_request_otp_sms(otp)
    app_signature = ENV['SIMPLE_APP_SIGNATURE']
    send_sms(I18n.t('sms.request_otp',
                    otp: otp,
                    app_signature: app_signature))
  end

  def send_reminder_whatsapp(reminder_type, appointment, callback_url, locale = DEFAULT_LOCALE)
    body = I18n.t("sms.appointment_reminders.#{reminder_type}",
                  facility_name: appointment.facility.name,
                  locale: locale)

    send_whatsapp(body, callback_url)
  end

  def send_reminder_sms(reminder_type, appointment, callback_url, locale = DEFAULT_LOCALE)
    body = I18n.t("sms.appointment_reminders.#{reminder_type}",
                  facility_name: appointment.facility.name,
                  locale: locale)

    send_sms(body, callback_url)
  end

  def send_patient_request_otp_sms(otp)
    send_sms(I18n.t('sms.patient_request_otp', otp: otp))
  end
=end

  def send_sms(recipient_number, message)
    sender_number    = twilio_sender_number
    recipient_number = parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message)
  end

  def send_whatsapp(recipient_number, message)
    sender_number    = "whatsapp:" + twilio_sender_number
    recipient_number = "whatsapp:" + parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message)
  end

  def parse_phone_number(number)
    parsed_number = Phonelib.parse(number, Rails.application.config.country[:abbreviation]).raw_national
    default_country_code + parsed_number
  end

  private

  def default_country_code
    Rails.application.config.country[:sms_country_code]
  end

  def send_twilio_message(sender_number, recipient_number, message)
    client.messages.create(
      from: sender_number,
      to: recipient_number,
      status_callback: twilio_callback_url,
      body: message
    )
  end

  def twilio_account_sid
    ENV.fetch('TWILIO_REMINDERS_ACCOUNT_SID')
  end

  def twilio_auth_token
    ENV.fetch('TWILIO_REMINDERS_ACCOUNT_AUTH_TOKEN')
  end

  def twilio_sender_number
    ENV.fetch('TWILIO_REMINDERS_ACCOUNT_PHONE_NUMBER')
  end

  def twilio_callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch('SIMPLE_SERVER_HOST'),
      protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL')
    )
  end
end
