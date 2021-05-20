class AppointmentNotificationService
  def self.send_after_missed_visit(*args)
    new(*args).send_after_missed_visit
  end

  def initialize(appointments:, days_overdue: 3)
    @appointments = appointments
    @days_overdue = days_overdue

    @communication_type = if Flipper.enabled?(:whatsapp_appointment_reminders)
      Communication.communication_types[:missed_visit_whatsapp_reminder]
    else
      Communication.communication_types[:missed_visit_sms_reminder]
    end
  end

  def send_after_missed_visit
    eligible_appointments = appointments.eligible_for_reminders(days_overdue: days_overdue)
    next_messaging_time = Communication.next_messaging_time

    eligible_appointments.each do |appointment|
      notification = appointment.notifications.create_reminder(
        remind_on: next_messaging_time,
        message: "#{Appointment::REMINDER_MESSAGE_PREFIX}.#{communication_type}"
      )
      AppointmentNotification::Worker.perform_at(next_messaging_time, notification.id)
    end
  end

  private

  attr_reader :appointments, :communication_type, :days_overdue
end
