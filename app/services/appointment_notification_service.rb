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
      # i actually don't this is correct. the twilio controller handles resend for failed communications
      # i think it makes more sense to check for any communications on the appoinment
      # leaving it in place for now
      next if appointment.previously_communicated_via?(communication_type)

      appointment_reminder = create_appointment_reminder(appointment)

      AppointmentNotification::Worker.perform_at(next_messaging_time, appointment_reminder.id, communication_type)
    end
  end

  private

  def create_appointment_reminder(appointment)
    AppointmentReminder.create!(
      appointment: appointment,
      patient: appointment.patient,
      remind_on: appointment.remind_on,
      status: "pending",
      message: "sms.appointment_reminders.#{communication_type}" # i believe the messages are always the same for both communication types
    )
  end

  attr_reader :appointments, :communication_type, :days_overdue
end
