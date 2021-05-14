require "rails_helper"

RSpec.describe AppointmentNotification::ScheduleExperimentReminders, type: :job do
  describe "#perform" do
    let(:appointment) { create(:appointment) }
    let(:today) { Date.current }

    before { Flipper.enable(:appointment_reminders) }

    it "does not schedule anything if appointment_reminders flag is off" do
      create(:appointment_reminder, appointment: appointment, remind_on: today, status: "pending")

      Flipper.disable(:appointment_reminders)
      expect(AppointmentNotification::Worker).not_to receive(:perform_at)
      described_class.perform_now
    end

    it "schedules the worker to send all pending appointment reminders with a remind_on of today" do
      _yesterday_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today - 1.day, status: "pending")
      _today_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "pending")
      _tomorrow_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today + 1.day, status: "pending")
      _scheduled_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "scheduled")
      _sent_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "sent")
      _cancelled_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "cancelled")

      expect(AppointmentNotification::Worker).to receive(:perform_at).exactly(1).times
      described_class.perform_now
    end

    # can't be tested in the previous spec because the expectations collide
    it "schedules the worker with the appointment reminder's id" do
      reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "pending")

      Timecop.freeze do
        next_messaging_time = Communication.next_messaging_time
        expect(AppointmentNotification::Worker).to receive(:perform_at).with(next_messaging_time, reminder.id).exactly(1).times
        described_class.perform_now
      end
    end

    it "updates the reminder status to 'scheduled'" do
      reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "pending")

      expect {
        described_class.perform_now
      }.to change { reminder.reload.status }.from("pending").to("scheduled")
    end
  end
end
