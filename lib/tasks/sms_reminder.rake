namespace :sms_reminder do
  desc 'Send automatic SMS reminder to patients who missed their scheduled visit by three days'
  task three_days_after_missed_visit: :environment do
    SMSReminderService.new(SMS_REMINDER_BOT_USER).three_days_after_missed_visit
  end
end
