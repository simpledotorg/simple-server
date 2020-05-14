class AppointmentNotification::Worker
  include Sidekiq::Worker

  DEFAULT_LOCALE = :en

  sidekiq_options queue: 'high'

  def perform(appointment, communication_type)
    return if appointment.previously_communicated_via?(communication_type)

    begin
      sms_response = NotificationService.new.send_whatsapp(
        appointment.patient.latest_mobile_number,
        appointment_message(appointment)
      )

      Communication.create_with_twilio_details!(
        appointment: appointment,
        twilio_sid: sms_response.sid,
        twilio_msg_status: sms_response.status,
        communication_type: communication_type
      )
    rescue Twilio::REST::TwilioError => e
      report_error(e)
    end
  end

  private

  def appointment_message(appointment)
     I18n.t(
       "sms.appointment_reminders.#{reminder_type}",
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
      tags: { type: 'appointment-notification-job' }
    )
  end
end
