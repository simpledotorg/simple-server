class NotificationService
  DEFAULT_LOCALE = :en

  attr_reader :client

  def initialize
    @client = Twilio::REST::Client.new(twilio_account_sid, twilio_account_token)
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

  def send_sms(sender_number, recipient_number, message)
    recipient_number = parse_phone_number(recipient_number)

    client.messages.create(
      from: sender_number,
      to: recipient_number.insert(0, Rails.application.config.country[:sms_country_code]),
      status_callback: twilio_callback_url,
      body: body)
  end

  def send_whatsapp(sender_number, recipient_number, message)
    recipient_number = parse_phone_number(recipient_number)

    client.messages.create(
      from: "whatsapp:" + sender_number,
      to: "whatsapp:" + recipient_number.insert(0, Rails.application.config.country[:sms_country_code]),
      status_callback: twilio_callback_url,
      body: body)
  end

  private

  def parse_phone_number(number)
    Phonelib.parse(number, Rails.application.config.country[:abbreviation]).raw_national
  end

  def twilio_account_sid
    ENV.fetch('TWILIO_REMINDERS_ACCOUNT_SID')
  end

  def twilio_auth_token
    ENV.fetch('TWILIO_REMINDERS_ACCOUNT_AUTH_TOKEN'))
  end

  def twilio_callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch('SIMPLE_SERVER_HOST'),
      protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL')
    )
  end
end
