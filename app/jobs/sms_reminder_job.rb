class SMSReminderJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  DEFAULT_RETRY_TIMES = 5
  DEFAULT_RETRY_SECONDS = 10.minutes.seconds.to_i

  def perform(type)
    reminder = SMSReminderService.new

    case type
    when 'three_days_after_missed_visit' then
      reminder.three_days_after_missed_visit
    else
      raise SMSReminderService::ReminderNotFound
    end
  end
end
