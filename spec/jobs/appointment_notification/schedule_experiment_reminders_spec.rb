require "rails_helper"

RSpec.describe AppointmentNotification::ScheduleExperimentReminders, type: :job do
  describe "#perform" do
    let(:appointment) { create(:appointment) }
    let(:today) { Date.current }

    it "schedules the worker to send all pending appointment reminders with a remind_on of today" do
      yesterday_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today - 1.day, status: "pending")
      today_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "pending")
      tomorrow_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today + 1.day, status: "pending")
      scheduled_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "scheduled")
      sent_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "sent")
      cancelled_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "cancelled")

      expect(AppointmentNotification::Worker).to receive(:perform_at).exactly(1).times

      described_class.perform_now
    end

    # only doing this because i couldn't test both expectations in the last specs
    it "schedules the worker with the appointment reminder's id" do
      today_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "pending")

      Timecop.freeze do
        next_messaging_time = Communication.next_messaging_time
        expect(AppointmentNotification::Worker).to receive(:perform_at).with(next_messaging_time, today_reminder.id, "missed_visit_whatsapp_reminder").exactly(1).times
        described_class.perform_now
      end
    end

    it "updates the reminder status to 'scheduled'" do
      today_reminder = create(:appointment_reminder, appointment: appointment, remind_on: today, status: "pending")

      expect {
        described_class.perform_now
      }.to change { today_reminder.reload.status }.from("pending").to("scheduled")
    end
  end
end