class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  DEFAULT_LOCALE = :en

  def perform(appointment_reminder_id)
    reminder = AppointmentReminder.includes(:appointment, :patient).find(appointment_reminder_id)
    return if reminder.appointment.previously_communicated_via?(communication_type)
    check_for_errors(reminder)
    send_message(reminder)
  end

  private

  def check_for_errors(reminder)
    if reminder.status != "scheduled"
      report_error("scheduled appointment reminder has invalid status")
    end
    if reminder.next_communication_type.nil?
      report_error("scheduled appointment reminder does not have a next communication type")
    end
  end

  def send_message(reminder)
    notification_service = NotificationService.new

    begin
      response = if reminder.next_communication_type == "missed_visit_whatsapp_reminder"
        notification_service.send_whatsapp(
          phone_number(reminder.patient),
          appointment_message(reminder),
          callback_url
        )
      else
        notification_service.send_sms(
          phone_number(reminder.patient),
          appointment_message(reminder),
          callback_url
        )
      end
      create_communication(reminder, response)
      mark_reminder_sent(reminder)
    rescue Twilio::REST::TwilioError => e
      report_error(e)
    end
  end

  def create_communication(reminder, response)
    Communication.create_with_twilio_details!(
      appointment: reminder.appointment,
      appointment_reminder: reminder,
      twilio_sid: response.sid,
      twilio_msg_status: response.status,
      communication_type: reminder.next_communication_type
    )
  end

  def mark_reminder_sent(reminder)
    reminder.status_sent!
  end

  def appointment_message(reminder)
    I18n.t(
      reminder.message,
      facility_name: appointment.facility.name,
      locale: patient_locale(reminder.patient)
    )
  end

  def patient_locale(patient)
    patient.address&.locale || DEFAULT_LOCALE
  end

  def phone_number(patient)
    patient.latest_mobile_number
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
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
end
