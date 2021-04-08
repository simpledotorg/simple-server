require "rails_helper"

RSpec.describe AppointmentReminders::SendDailyRemindersJob, type: :job do
  describe "#perform" do
    it "schedules send_reminder_job for all appointment reminders with a remind_on of today" do
      reminder1 = create(:appointment_reminder, remind_on: 1.day.ago)
      reminder2 = create(:appointment_reminder, remind_on: Date.current)
      reminder3 = create(:appointment_reminder, remind_on: 1.day.from_now)

      schedule_time = 5.minutes.from_now
      allow(Communication).to receive(:next_messaging_time).and_return(schedule_time)

      expect(AppointmentReminders::SendReminderJob).not_to receive(:perform_at).with(schedule_time, reminder1)
      expect(AppointmentReminders::SendReminderJob).to receive(:perform_at).with(schedule_time, reminder2)
      expect(AppointmentReminders::SendReminderJob).not_to receive(:perform_at).with(schedule_time, reminder3)

      AppointmentReminders::SendDailyRemindersJob.perform_now
    end
  end
end