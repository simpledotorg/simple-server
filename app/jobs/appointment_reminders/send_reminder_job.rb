class AppointmentReminders::SendReminderJob
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  # i think this should be based on country instead
  DEFAULT_LOCALE = :en

  def perform(reminder_id)
    reminder = AppointmentReminder.includes(:appointment, :patient).find(reminder_id)
    send_message(reminder)
  end

  private

  def send_message(reminder)
    notification_service = NotificationService.new
    # i think this logic should be handled by the notification service
    response = if communication_type == "missed_visit_whatsapp_reminder"
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

    Communication.create_with_twilio_details!(
      appointment: reminder.appointment,
      twilio_sid: response.sid,
      twilio_msg_status: response.status,
      communication_type: communication_type
    )
  end

  def appointment_message(reminder)
    I18n.t(
      reminder.message,
      assigned_facility_name: reminder.appointment.facility.name,
      patient_name: reminder.patient.full_name,
      appointment_date: reminder.appointment.scheduled_date,
      locale: patient_locale(reminder.patient)
    )
  end

  def patient_locale(patient)
    patient.address&.locale || DEFAULT_LOCALE
  end

  # this should only be india for now
  def communication_type
    type = CountryConfig.current[:name] == "India" ? :missed_visit_whatsapp_reminder : :missed_visit_sms_reminder
    Communication.communication_types[type]
  end

  # perhaps abort if not found, but that shouldn't happen
  def phone_number(patient)
    patient.latest_mobile_number
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end
end
