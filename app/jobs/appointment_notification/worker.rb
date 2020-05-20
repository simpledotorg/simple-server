class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: 'high'

  DEFAULT_LOCALE = :en

  def perform(appointment_id, communication_type, locale = DEFAULT_LOCALE)
    appointment = Appointment.find(appointment_id)

    return if appointment.previously_communicated_via?(communication_type)

    patient_phone_number = appointment.patient.latest_mobile_number
    message = appointment_message(appointment, communication_type, locale)

    begin
      notification_service = NotificationService.new

      if FeatureToggle.enabled?("WHATSAPP_APPOINTMENT_REMINDERS")
        response = notification_service.send_whatsapp(patient_phone_number, message, callback_url)
      else
        response = notification_service.send_sms(patient_phone_number, message, callback_url)
      end

      Communication.create_with_twilio_details!(
        appointment: appointment,
        twilio_sid: response.sid,
        twilio_msg_status: response.status,
        communication_type: communication_type
      )
    rescue Twilio::REST::TwilioError => e
      report_error(e)
    end
  end

  private

  def appointment_message(appointment, communication_type, locale)
    I18n.t(
      "sms.appointment_reminders.#{communication_type}",
      facility_name: appointment.facility.name,
      locale: locale
    )
  end

  def report_error(e)
    Raven.capture_message(
      'Error while processing appointment notifications',
      logger: 'logger',
      extra: {
        exception: e.to_s
      },
      tags: {
        type: 'appointment-notification-job'
      }
    )
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch('SIMPLE_SERVER_HOST'),
      protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL')
    )
  end
end
