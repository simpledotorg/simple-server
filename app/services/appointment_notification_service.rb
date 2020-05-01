class AppointmentNotificationService
  FAN_OUT_BATCH_SIZE = (ENV['APPOINTMENT_NOTIFICATION_FAN_OUT_BATCH_SIZE'].presence || 250).to_i

  private

  attr_reader :appointments, :schedule_at

  class << self
    def send_after_missed_visit(appointments:, days_overdue: 3, schedule_at:)
      overdue_appts_with_patient_consent = appointments.overdue_by(days_overdue)
                          .includes(patient: [:phone_numbers])
                          .where(patients: { reminder_consent: 'granted' })
                          .merge(PatientPhoneNumber.phone_type_mobile)

      fan_out_reminders(overdue_appts_with_patient_consent,
        Communication.communication_types[:missed_visit_sms_reminder],
        schedule_at)
    end

    def fan_out_reminders(appointments, communication_type, schedule_at)
      eligible_appointments(appointments, communication_type)
        .map(&:id)
        .each_slice(FAN_OUT_BATCH_SIZE) do |appointments_batch|
        AppointmentNotification::Worker.perform_at(schedule_at, appointments_batch, communication_type)
      end
    end

    def eligible_appointments(appointments, communication_type)
      appointments.select { |appointment| !appointment.previously_communicated_via?(communication_type) }
    end
  end
end
