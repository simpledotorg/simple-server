class AppointmentReminders::SendDailyRemindersJob < ApplicationJob
  queue_as :high

  def perform
    # add feature flag
    # we need to either ensure this is done same day or change how this works, perhaps just scheduling
    # to occur when we want it to
    next_messaging_time = Communication.next_messaging_time
    reminders = AppointmentReminder.where(remind_on: Date.current).includes(:appointment, :patient)
    reminders.each do |reminder|
      AppointmentReminders::SendReminderJob.perform_at(next_messaging_time, reminder)
    end
  end
end