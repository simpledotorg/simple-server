class ExperimentNotification::Worker
  # This is more or less identical to AppointmentNotification::Worker
  # The primary difference is that this worker uses the `experiment` to fetch the appropriate message to send
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  DEFAULT_LOCALE = :en

  def perform(experiment, appointment_id, communication_type, locale = nil)
    appointment = Appointment.find_by(id: appointment_id)
    unless appointment
      logger.warn "Appointment #{appointment_id} not found, skipping notification"
      return
    end

    patient_phone_number = appointment.patient.latest_mobile_number
    message = experiment_message(experiment, appointment, communication_type, locale)

    begin
      notification_service = NotificationService.new

      response = if communication_type == "experimental_whatsapp_reminder"
        notification_service.send_whatsapp(patient_phone_number, message, callback_url)
      else
        notification_service.send_sms(patient_phone_number, message, callback_url)
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

  def experiment_message(appointment, communication_type, locale)
    I18n.t(
      experiment.fetch_message(appointment, communication_type, locale),
      facility_name: appointment.facility.name,
      locale: appointment_locale(appointment, locale)
    )
  end

  def appointment_locale(appointment, locale)
    locale || appointment.patient.address&.locale || DEFAULT_LOCALE
  end

  def report_error(e)
    Sentry.capture_message(
      "Error while processing appointment notifications",
      extra: {
        exception: e.to_s
      },
      tags: {
        type: "appointment-notification-job"
      }
    )
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end
end
