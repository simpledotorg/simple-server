class AppointmentNotificationJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include SmsHelper

  queue_as :default
  self.queue_adapter = :sidekiq

  # disable retries
  sidekiq_options retry: 0

  def perform(appointment_ids, communication_type, user)
    Appointment.where(id: appointment_ids).each do |appointment|
      next if appointment.previously_communicated_via?(communication_type)

      begin
        sms_response = send_sms(appointment, type)
        Communication.create_with_twilio_details!(user: user,
                                                  appointment: appointment,
                                                  twilio_sid: sms_response.sid,
                                                  twilio_msg_status: sms_response.status,
                                                  communication_type: communication_type)
      rescue StandardError
        next
      end
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
