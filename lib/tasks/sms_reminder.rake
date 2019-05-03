namespace :sms_reminder do
  desc 'Send automatic SMS reminder to patients who missed their scheduled visit by three days'
  task send_after_missed_visit: :environment do
    AppointmentNotificationService
      .new(SMS_REMINDER_BOT_USER, 250)
      .send_after_missed_visit(days_overdue: 3)
  end
end
