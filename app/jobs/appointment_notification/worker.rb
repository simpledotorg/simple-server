class AppointmentNotification::Worker
  include Sidekiq::Worker
  sidekiq_options queue: 'high'

  DEFAULT_LOCALE = :en

  def perform(appointment_id, communication_type, locale = DEFAULT_LOCALE)
    appointment = Appointment.find(appointment_id)

    return if appointment.previously_communicated_via?(communication_type)

    patient_phone_number = appointment.patient.latest_mobile_number
    message = appointment_message(appointment, communication_type, locale)

    begin
      response = NotificationService.new.send_whatsapp(patient_phone_number, message)

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
end
