class AppointmentNotificationJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include SmsHelper

  queue_as :default
  self.queue_adapter = :sidekiq

  # essentially, disable retries on exceptions
  retry_on StandardError, attempts: 0

  def perform(appointments, communication_type, user)
    Appointment.where(id: appointments).each do |appointment|
      next if !within_time_window? || appointment.previously_communicated_via?(communication_type)

      begin
        sms_response = send_sms(appointment, communication_type)
        Communication.create_with_twilio_details!(user: user,
                                                  appointment: appointment,
                                                  twilio_sid: sms_response.sid,
                                                  twilio_msg_status: sms_response.status,
                                                  communication_type: communication_type)

      rescue StandardError => e
        report_error(e)
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
                         sms_delivery_callback_url,
                         sms_locale(appointment.patient.address.state_to_sym))
  end

  def sms_delivery_callback_url
    api_current_twilio_sms_delivery_url(host: ENV.fetch('SIMPLE_SERVER_HOST'),
                                        protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL'))
  end

  def within_time_window?
    DateTime
      .now
      .in_time_zone(ENV.fetch('DEFAULT_TIME_ZONE'))
      .hour
      .between?(Config.get_int('APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_START',
                               AppointmentNotificationService::DEFAULT_TIME_WINDOW_START),
                Config.get_int('APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_END',
                               AppointmentNotificationService::DEFAULT_TIME_WINDOW_END))
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
