class AppointmentNotificationService
  def self.send_after_missed_visit(*args)
    new(*args).send_after_missed_visit
  end

  def initialize(appointments:, days_overdue: 3)
    @appointments = appointments
    @days_overdue = days_overdue

    @communication_type = if FeatureToggle.enabled?("WHATSAPP_APPOINTMENT_REMINDERS")
      Communication.communication_types[:missed_visit_whatsapp_reminder]
    else
      Communication.communication_types[:missed_visit_sms_reminder]
    end
  end

  def send_after_missed_visit
    eligible_appointments = appointments.eligible_for_reminders(days_overdue: days_overdue)
    next_messaging_time = Communication.next_messaging_time

    eligible_appointments.each do |appointment|
      # i don't believe this is the best way to control this. combined with the fact that
      # we grab all appointments with remind_on before today, I suspect this means we're
      # resending the same reminders because they failed the first time.
      # leaving it in place for now in an effort to change as little of the current process as possible.
      next if appointment.previously_communicated_via?(communication_type)

      appointment_reminder = create_appointment_reminder(appointment)

      AppointmentNotification::Worker.perform_at(next_messaging_time, appointment_reminder.id)
    end
  end

  private

  def create_appointment_reminder(appointment)
    AppointmentReminder.create!(
      appointment: appointment,
      patient: appointment.patient,
      remind_on: appointment.remind_on,
      status: "pending",
      message: "sms.appointment_reminders.#{communication_type}"
    )
  end

  attr_reader :appointments, :communication_type, :days_overdue
end
