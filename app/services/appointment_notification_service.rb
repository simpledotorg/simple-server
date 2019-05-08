class AppointmentNotificationService
  include TargetedReleasable
  FAN_OUT_BATCH_SIZE = 250

  def initialize(user)
    @user = user
  end

  def send_after_missed_visit(days_overdue: 3, schedule_at:)
    fan_out_reminders(Appointment.overdue_by(days_overdue).includes(patient: [:phone_numbers]),
                      Communication.communication_types[:missed_visit_sms_reminder],
                      schedule_at)
  end

  private

  attr_reader :user, :schedule_at, :appointments

  def fan_out_reminders(appointments, communication_type, schedule_at)
    appointments
      .select { |appointment| eligible_for_sending_sms?(appointment, communication_type) }
      .sample(roll_out_for(appointments.size, 'APPOINTMENT_NOTIFICATION_ROLLOUT_PERCENTAGE'))
      .each_slice(FAN_OUT_BATCH_SIZE) do |appointments_batch|
      AppointmentNotification::Worker.perform_at(schedule_at,
                                                 user.id,
                                                 appointments_batch.map(&:id),
                                                 communication_type)
    end
  end

  def eligible_for_sending_sms?(appointment, communication_type)
    facility_eligible?(appointment.facility_id, 'APPOINTMENT_NOTIFICATION_FACILITY_IDS') &&
      (not appointment.previously_communicated_via?(communication_type)) &&
      appointment.patient.phone_number?
  end
end
