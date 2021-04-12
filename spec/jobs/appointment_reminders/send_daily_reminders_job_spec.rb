require "rails_helper"

RSpec.describe AppointmentReminders::SendDailyRemindersJob, type: :job do
  describe "#perform" do
    it "schedules send_reminder_job for all appointment reminders with a remind_on of today" do
      past = create(:appointment_reminder, remind_on: 1.day.ago, status: "pending")
      current = create(:appointment_reminder, remind_on: Date.current, status: "pending")
      upcoming = create(:appointment_reminder, remind_on: 1.day.from_now, status: "pending")

      schedule_time = 5.minutes.from_now
      allow(Communication).to receive(:next_messaging_time).and_return(schedule_time)

      expect(AppointmentReminders::SendReminderJob).not_to receive(:perform_at).with(schedule_time, past.id)
      expect(AppointmentReminders::SendReminderJob).to receive(:perform_at).with(schedule_time, current.id)
      expect(AppointmentReminders::SendReminderJob).not_to receive(:perform_at).with(schedule_time, upcoming.id)

      AppointmentReminders::SendDailyRemindersJob.perform_now
    end

    it "only schedules pending appointment reminders" do
      pending = create(:appointment_reminder, remind_on: Date.current, status: "pending")
      scheduled = create(:appointment_reminder, remind_on: Date.current, status: "scheduled")
      sent = create(:appointment_reminder, remind_on: Date.current, status: "sent")
      cancelled = create(:appointment_reminder, remind_on: Date.current, status: "cancelled")

      schedule_time = 5.minutes.from_now
      allow(Communication).to receive(:next_messaging_time).and_return(schedule_time)

      expect(AppointmentReminders::SendReminderJob).to receive(:perform_at).with(schedule_time, pending.id)
      expect(AppointmentReminders::SendReminderJob).not_to receive(:perform_at).with(schedule_time, scheduled.id)
      expect(AppointmentReminders::SendReminderJob).not_to receive(:perform_at).with(schedule_time, sent.id)
      expect(AppointmentReminders::SendReminderJob).not_to receive(:perform_at).with(schedule_time, cancelled.id)

      AppointmentReminders::SendDailyRemindersJob.perform_now
    end

    it "updates status to scheduled" do
      pending = create(:appointment_reminder, remind_on: Date.current, status: "pending")

      schedule_time = 5.minutes.from_now
      allow(Communication).to receive(:next_messaging_time).and_return(schedule_time)

      expect {
        AppointmentReminders::SendDailyRemindersJob.perform_now
      }.to change { pending.reload.status }.from("pending").to("scheduled")
    end
  end
end
