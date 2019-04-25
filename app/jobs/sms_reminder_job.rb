class SMSReminderJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default
  self.queue_adapter = :sidekiq

  DEFAULT_RETRY_TIMES = 5
  DEFAULT_RETRY_SECONDS = 10.minutes.seconds.to_i

  def perform(appointment_id, type)
    appointment = Appointment.find(appointment_id)
    sms_response = send_sms(appointment, type)
    Communication.create_with_twilio_details!(user: BOT_USER,
                                              appointment: appointment,
                                              twilio_session_id: sms_response.sid,
                                              twilio_msg_status: sms_response.status)
  end

  private

  def send_sms(appointment, type)
    SmsNotificationService
      .new(appointment.patient.latest_phone_number)
      .send_reminder_sms(type,
                         appointment,
                         twilio_sms_delivery_url,
                         SmsHelper::sms_locale(appointment.patient.address))
  end

  def twilio_sms_delivery_url
    api_current_twilio_sms_delivery_url(host: ENV.fetch('SIMPLE_SERVER_HOSTNAME'),
                                        protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL'))
  end
end
