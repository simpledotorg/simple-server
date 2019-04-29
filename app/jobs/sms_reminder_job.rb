class SMSReminderJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include SmsHelper

  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(appointment_ids, type, user)
    appointments = Appointment.where(id: appointment_ids)
    appointments.each do |appointment|
      sms_response = send_sms(appointment, type)
      Communication.create_with_twilio_details!(user: user,
                                                appointment: appointment,
                                                twilio_session_id: sms_response.sid,
                                                twilio_msg_status: sms_response.status)
    end
  end

  private

  def send_sms(appointment, type)
    SmsNotificationService
      .new(appointment.patient.latest_phone_number)
      .send_reminder_sms(type,
                         appointment,
                         twilio_sms_delivery_url,
                         sms_locale(appointment.patient.address.state_to_sym))
  end

  def twilio_sms_delivery_url
    api_current_twilio_sms_delivery_url(host: ENV.fetch('SIMPLE_SERVER_HOST'),
                                        protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL'))
  end
end
