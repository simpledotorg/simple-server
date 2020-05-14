class AppointmentNotification::Worker
  include Sidekiq::Worker

  sidekiq_options queue: 'high'

  def perform(appointment, communication_type)
    return if appointment.previously_communicated_via?(communication_type)

    begin
      sms_response = send_sms(appointment, communication_type)
      Communication.create_with_twilio_details!(appointment: appointment,
                                                twilio_sid: sms_response.sid,
                                                twilio_msg_status: sms_response.status,
                                                communication_type: communication_type)

    rescue Twilio::REST::TwilioError => e
      report_error(e)
    end
  end

  private

  SMS_CLIENT = Twilio::REST::Client.new(ENV.fetch('TWILIO_REMINDERS_ACCOUNT_SID'),
                                        ENV.fetch('TWILIO_REMINDERS_ACCOUNT_AUTH_TOKEN'))

  def send_sms(appointment, type)
    SmsNotificationService
      .new(appointment.patient.latest_mobile_number,
           ENV.fetch('TWILIO_REMINDERS_ACCOUNT_PHONE_NUMBER'),
           SMS_CLIENT)
      .send_reminder_sms(type,
                         appointment,
                         sms_delivery_callback_url,
                         appointment.patient.address.locale)
  end

  def sms_delivery_callback_url
    api_v3_twilio_sms_delivery_url(host: ENV.fetch('SIMPLE_SERVER_HOST'),
                                        protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL'))
  end


  def report_error(e)
    Raven.capture_message(
      'Error while processing appointment notifications',
      logger: 'logger',
      extra: {
        exception: e.to_s
      },
      tags: { type: 'appointment-notification-job' })
  end
end
