class AppointmentReminders::SendReminderJob < ApplicationJob
  queue_as :high

  def perform(reminder)
    @reminder = reminder
    @patient = reminder.patient
    @appointment = reminder.appointment
  end

  private

  def send_message
    notification_service = NotificationService.new
    begin
      response = notification_service.send_whatsapp(phone_number, appointment_message, callback_url)
    rescue Twilio::REST::TwilioError => e
      # report_error(e)
    end

    Communication.create_with_twilio_details!(
      appointment: @appointment,
      twilio_sid: response.sid,
      twilio_msg_status: response.status,
      communication_type: communication_type
    )
  end

  def appointment_message
    I18n.t(
      @reminder.message,
      assigned_facility_name: @appointment.facility.name, #slightly less accurate than @patient.assigned_facility
      patient_name: @patient.name,
      appointment_date: @appointment.scheduled_date,
      locale: locale
    )
  end

  def locale
    @appointment.patient.address&.locale
  end

  def communication_type
    type = CountryConfig.current[:name] == "India" ? :missed_visit_whatsapp_reminder : missed_visit_sms_reminder
    Communication.communication_type[type]
  end

  # perhaps abort if not found, but that shouldn't happen
  def phone_number
    @patient.latest_mobile_number
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end
end