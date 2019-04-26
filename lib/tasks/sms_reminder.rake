namespace :sms_reminder do
  desc 'Send automatic SMS reminder to patients who missed their scheduled visit by three days'
  task three_days_after_missed_visit: :environment do
    SMSReminderService.new(BOT_USER).three_days_after_missed_visit
  end
end
