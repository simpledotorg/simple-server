class AppointmentNotificationService
  FAN_OUT_BATCH_SIZE = (ENV['APPOINTMENT_NOTIFICATION_FAN_OUT_BATCH_SIZE'].presence || 1).to_i

  def self.send_after_missed_visit(*args)
    new(*args).send_after_missed_visit
  end

  def initialize(appointments:, days_overdue: 3, schedule_at:)
    @appointments = appointments
    @days_overdue = days_overdue
    @schedule_at = schedule_at
    @communication_type = Communication.communication_types[:missed_visit_sms_reminder]
  end

  def send_after_missed_visit
    overdue_with_patient_consent = appointments.overdue_by(days_overdue)
                        .includes(patient: [:phone_numbers])
                        .where(patients: { reminder_consent: 'granted' })
                        .merge(PatientPhoneNumber.phone_type_mobile)

    overdue_and_not_previously_notified = overdue_with_patient_consent.select do |appointment|
      !appointment.previously_communicated_via?(communication_type)
    end

    fan_out_reminders(overdue_and_not_previously_notified, communication_type)
  end

  private

  attr_reader :appointments, :communication_type, :days_overdue, :schedule_at

  def fan_out_reminders(appointments_to_notify, communication_type)
    appointments_to_notify.map(&:id).each_slice(FAN_OUT_BATCH_SIZE) do |appointments_batch|
      AppointmentNotification::Worker.perform_at(schedule_at, appointments_batch, communication_type)
    end
  end

end
