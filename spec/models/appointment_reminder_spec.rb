require "rails_helper"

describe AppointmentReminder, type: :model do
  let(:appointment) { create(:appointment) }
  let(:appointment_reminder) { create(:appointment_reminder, appointment: appointment) }

  describe "associations" do
    it { should belong_to(:appointment) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
  end
end
