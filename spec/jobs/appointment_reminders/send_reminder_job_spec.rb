require "rails_helper"

RSpec.describe AppointmentReminders::SendReminderJob, type: :job do
  describe "#perform" do
    it "schedules send_reminder_job for all appointment reminders with a remind_on of today" do
      reminder1 = create(:appointment_reminder, remind_on: 1.day.ago)

    end
  end
end