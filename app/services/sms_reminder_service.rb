class SMSReminderService
  def three_days_after_missed_visit
    Appointment
      .overdue
      .select { |a| a.days_overdue > 3 }
      .group_by(&:facility_id)
      .slice(*ENV.fetch('SMS_REMINDER_ROLLOUT_FACILITY_IDS').split(','))
      .flat_map { |_, appointments| appointments.sample(rollout_percentage(appointments.size)) }
      .in_groups_of(1000) do |appointments|

      eligible_appointments = appointments.select { |a| a.reminder_messages_around(3).present? }
      SMSReminderJob.perform_later(eligible_appointments)
    end
  end

  private

  def rollout_percentage(total)
    (ENV.fetch('SMS_REMINDER_ROLLOUT_PER_FACILITY') / 100.0) * total
  end
end
