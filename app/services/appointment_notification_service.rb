class AppointmentNotificationService
  DEFAULT_TIME_WINDOW_START = 14
  DEFAULT_TIME_WINDOW_END = 16

  def initialize(user, reminders_batch_size)
    @user = user
    @reminders_batch_size = reminders_batch_size
    @targeted_release = TargetedReleaseService.new
  end

  def send_after_missed_visit(days_overdue: 3)
    communication_type = Communication.communication_types[:missed_visit_sms_reminder]

    eligible_appointments = Appointment
                              .overdue_by(days_overdue)
                              .includes(patient: [:phone_numbers])
                              .select { |appointment| eligible_for_sending_sms?(appointment, communication_type) }
    fan_out_reminders_by_facility(eligible_appointments, communication_type)
  end

  private

  attr_reader :user, :reminders_batch_size

  def eligible_for_sending_sms?(appointment, communication_type)
    !appointment.previously_communicated_via?(communication_type) &&
      appointment.patient.phone_number?
  end

  def fan_out_reminders_by_facility(appointments, communication_type)
    appointments
      .group_by(&:facility_id)
      .select { |facility_id, _| @targeted_release.facility_eligible?(facility_id) }
      .map do |_, grouped_appointments|
      grouped_appointments.each_slice(reminders_batch_size) do |appointments_batch|
        AppointmentNotificationJob
          .set(wait_until: schedule_at(Config.get_int('APPOINTMENT_NOTIFICATION_WINDOW_HOUR_OF_DAY_START',
                                                      DEFAULT_TIME_WINDOW_START)))
          .perform_later(appointments_batch, communication_type, @user)
      end
    end
  end

  def schedule_at(hour_of_day)
    now = DateTime.now.in_time_zone(ENV.fetch('DEFAULT_TIME_ZONE'))
    now.hour < hour_of_day ? now.change(hour: hour_of_day) : now.change(hour: hour_of_day) + 1.day
  end
end
