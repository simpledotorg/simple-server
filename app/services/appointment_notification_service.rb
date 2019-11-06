class AppointmentNotificationService
  include TargetedReleasable

  FAN_OUT_BATCH_SIZE = 250

  def send_after_missed_visit(days_overdue: 3, schedule_at:)
    fan_out_reminders(Appointment.overdue_by(days_overdue).includes(patient: [:phone_numbers]),
                      Communication.communication_types[:missed_visit_sms_reminder],
                      schedule_at)
  end

  private

  attr_reader :appointments, :schedule_at

  def fan_out_reminders(appointments, communication_type, schedule_at)
    eligible_appointments = appointments.select do |appointment|
      eligible_for_sending_sms?(appointment,
                                communication_type)
    end

    sampled_appointments = eligible_appointments
                             .group_by(&:facility_id)
                             .flat_map do |_, facility_appointments|
      facility_appointments.sample(roll_out_for(facility_appointments.size,
                                                'APPOINTMENT_NOTIFICATION_ROLLOUT_PERCENTAGE'))
    end

    sampled_appointments.each_slice(FAN_OUT_BATCH_SIZE) do |appointments_batch|
      AppointmentNotification::Worker.perform_at(schedule_at,
                                                 appointments_batch.map(&:id),
                                                 communication_type)
    end
  end

  def eligible_for_sending_sms?(appointment, communication_type)
    facility_eligible?(appointment.facility_id, 'APPOINTMENT_NOTIFICATION_FACILITY_IDS') &&
      (not appointment.previously_communicated_via?(communication_type)) &&
      appointment.patient&.phone_number?
  end
end
