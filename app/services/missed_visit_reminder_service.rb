class MissedVisitReminderService
  def self.send_after_missed_visit(*args)
    new(*args).send_after_missed_visit
  end

  def initialize(appointments:, days_overdue: 3)
    @appointments = appointments
    @days_overdue = days_overdue

    @communication_type = if Flipper.enabled?(:whatsapp_appointment_reminders)
      Communication.communication_types[:whatsapp]
    else
      Communication.communication_types[:sms]
    end
  end

  def send_after_missed_visit
    eligible_appointments = appointments.eligible_for_reminders(days_overdue: days_overdue)
    next_messaging_time = Communication.next_messaging_time

    eligible_appointments.each do |appointment|
      notification = create_reminder(appointment, remind_on: next_messaging_time)
      AppointmentNotification::Worker.perform_at(next_messaging_time, notification.id)
    end
  end

  private

  def create_reminder(appointment, remind_on:)
    Notification.create!(
      subject: appointment,
      patient: appointment.patient,
      remind_on: remind_on,
      status: "scheduled",
      message: "communications.appointment_reminders.#{communication_type}",
      purpose: "missed_visit_reminder"
    )
  end

  attr_reader :appointments, :communication_type, :days_overdue
end
