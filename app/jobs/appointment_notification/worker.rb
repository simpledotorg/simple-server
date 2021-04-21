class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  DEFAULT_LOCALE = :en

  def perform(appointment_reminder_id)
    reminder = AppointmentReminder.includes(:appointment, :patient).find(appointment_reminder_id)
    communication_type = reminder.next_communication_type
    return unless communication_type

    return if reminder.status != "scheduled"
    send_message(reminder, communication_type)
  end

  private

  def send_message(reminder, communication_type)
    notification_service = NotificationService.new

    if communication_type == "missed_visit_whatsapp_reminder"
      notification_service.send_whatsapp(
        reminder.patient.latest_mobile_number,
        appointment_message(reminder),
        callback_url
      )
    else
      notification_service.send_sms(
        reminder.patient.latest_mobile_number,
        appointment_message(reminder),
        callback_url
      )
    end

    return if notification_service.failed?

    ActiveRecord::Base.transaction do
      create_communication(reminder, communication_type, notification_service.response)
      reminder.status_sent!
    end
  end

  def create_communication(reminder, communication_type, response)
    Communication.create_with_twilio_details!(
      appointment: reminder.appointment,
      appointment_reminder: reminder,
      twilio_sid: response.sid,
      twilio_msg_status: response.status,
      communication_type: communication_type
    )
  end

  def appointment_message(reminder)
    I18n.t(
      reminder.message,
      facility_name: reminder.appointment.facility.name,
      locale: patient_locale(reminder.patient)
    )
  end

  def patient_locale(patient)
    patient.address&.locale || DEFAULT_LOCALE
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end
end
