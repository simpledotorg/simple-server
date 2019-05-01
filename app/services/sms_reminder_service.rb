class SMSReminderService
  def initialize(user, reminders_batch_size)
    @user = user
    @reminders_batch_size = reminders_batch_size
    @targeted_release = TargetedReleaseService.new
  end

  def three_days_after_missed_visit
    eligible_appointments = Appointment
                              .overdue_by(3)
                              .left_joins(:communications)
                              .select(&:undelivered_followup_messages?)

    fan_out_reminders_by_facility(eligible_appointments, 'follow_up_reminder')
  end

  private

  def fan_out_reminders_by_facility(appointments, type)
    appointments
      .group_by(&:facility_id)
      .select { |facility_id, _| @targeted_release.facility_eligible?(facility_id) }
      .map do |_, grouped_appointments|
      grouped_appointments.each_slice(@reminders_batch_size) do |appointments_batch|
        appointment_ids = appointments_batch.map(&:id)
        SMSReminderJob.perform_later(appointment_ids, type, @user)
      end
    end
  end
end
