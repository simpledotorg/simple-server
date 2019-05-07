class AppointmentNotificationService
  include TargetedRelease

  DEFAULT_TIME_WINDOW_END = 16
  DEFAULT_TIME_WINDOW_START = 14

  def initialize(user, reminders_batch_size)
    @user = user
    @reminders_batch_size = reminders_batch_size
    @schedule_at_hour_of_day = Config.get_int('APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_START',
                                              DEFAULT_TIME_WINDOW_START)
  end

  def send_after_missed_visit(days_overdue: 3)
    communication_type = Communication.communication_types[:missed_visit_sms_reminder]

    eligible_appointments = Appointment
                              .overdue_by(days_overdue)
                              .includes(patient: [:phone_numbers])
                              .select { |appointment| eligible_for_sending_sms?(appointment, communication_type) }
    fan_out_reminders(eligible_appointments, communication_type)
  end

  private

  attr_reader :user, :reminders_batch_size, :schedule_at_hour_of_day

  def eligible_for_sending_sms?(appointment, communication_type)
    facility_eligible?(appointment.facility_id, 'APPOINTMENT_NOTIFICATION_FACILITY_IDS') &&
      (not appointment.previously_communicated_via?(communication_type)) &&
      appointment.patient.phone_number?
  end

  def fan_out_reminders(appointments, communication_type)
    appointments
      .sample(roll_out_batch(appointments.size, 'APPOINTMENT_NOTIFICATION_ROLLOUT_PERCENTAGE'))
      .each_slice(reminders_batch_size) do |appointments_batch|
      AppointmentNotificationJob
        .set(wait_until: schedule_at)
        .perform_later(appointments_batch, communication_type, @user)
    end
  end

  def schedule_at
    now = DateTime.now.in_time_zone(ENV.fetch('DEFAULT_TIME_ZONE'))
    now.hour < @schedule_at_hour_of_day ?
      now.change(hour: @schedule_at_hour_of_day) :
      now.change(hour: @schedule_at_hour_of_day) + 1.day
  end
end
