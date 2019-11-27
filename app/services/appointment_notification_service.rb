class AppointmentNotificationService < Struct.new(:organization)
  FAN_OUT_BATCH_SIZE = 250

  def send_after_missed_visit(days_overdue: 3, schedule_at:)
    fan_out_reminders(Appointment.overdue_by(days_overdue)
                          .includes(patient: [:phone_numbers], facility: { facility_group: :organization })
                          .where(facility: { facility_groups: { organization: organization } })
                          .where(patients: { reminder_consent: :granted }),
                      Communication.communication_types[:missed_visit_sms_reminder],
                      schedule_at)
  end

  private

  attr_reader :appointments, :schedule_at

  def fan_out_reminders(appointments, communication_type, schedule_at)
    eligible_appointments(appointments, communication_type)
        .map(&:id)
        .each_slice(FAN_OUT_BATCH_SIZE) do |appointments_batch|
      AppointmentNotification::Worker.perform_at(schedule_at, appointments_batch, communication_type)
    end
  end

  def eligible_appointments(appointments, communication_type)
    appointments.select { |appointment| eligible_for_sending_sms?(appointment, communication_type) }
  end

  def eligible_for_sending_sms?(appointment, communication_type)
    (not appointment.previously_communicated_via?(communication_type)) && appointment.patient&.phone_number?
  end
end
