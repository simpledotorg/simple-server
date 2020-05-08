class AppointmentNotificationService
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

    overdue_with_patient_consent.each do |appointment|
      next if appointment.previously_communicated_via?(communication_type)

      AppointmentNotification::Worker.perform_at(schedule_at, appointment.id, communication_type)
    end
  end

  private

  attr_reader :appointments, :communication_type, :days_overdue, :schedule_at
end
