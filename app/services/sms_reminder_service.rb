class SMSReminderService < Struct.new(:user)
  def three_days_after_missed_visit
    eligible_appointments = Appointment
                              .overdue
                              .select do |a|
      a.days_overdue > 3 &&
        a.undelivered_reminder_messages(days_since_scheduled_visit: 3).present? &&
        TargetedReleaseService.new.facilities.include?(a.facility_id)
    end

    fan_out_reminders_by_facility(eligible_appointments, '3_days_after_missed_visit')
  end

  private

  FAN_OUT_BATCH_SIZE = 250

  def fan_out_reminders_by_facility(appointments, type)
    appointments
      .group_by(&:facility_id)
      .map do |_, grouped_appointments|
      grouped_appointments.in_groups_of(FAN_OUT_BATCH_SIZE)
        .flatten
        .each do |appointments_batch|
        SMSReminderJob.perform_later(appointments_batch.map(&:id), type, user)
      end
    end
  end
end
