class SMSReminderService
  include Rails.application.routes.url_helpers

  def three_days_after_missed_visit
    days_overdue = 3

    Appointment.overdue.select { |a| a.days_overdue > days_overdue }.each do |appointment|
      unless appointment.reminder_messages_around(days_overdue).present?
        sms_response = send_sms(appointment, '3_days_after_missed_visit')
        Communication.create_with_twilio_details!(user: BOT_USER,
                                                  appointment: appointment,
                                                  twilio_session_id: sms_response.sid,
                                                  twilio_msg_status: sms_response.status)
      end
    end
  end

  private

  def send_sms(appointment, type)
    SmsNotificationService
      .new(appointment.patient.phone_numbers.last.number)
      .send_reminder_sms(type,
                         appointment,
                         twilio_sms_delivery_url,
                         SmsHelper::sms_locale(appointment.patient.address))
  end

  def twilio_sms_delivery_url
    api_current_twilio_sms_delivery_url(host: ENV.fetch('SIMPLE_SERVER_HOSTNAME'),
                                        protocol: ENV.fetch('SIMPLE_SERVER_HOST_PROTOCOL'))
  end
end
