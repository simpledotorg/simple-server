require "rails_helper"

describe AppointmentReminder, type: :model do
  describe "associations" do
    it { should belong_to(:appointment) }
    it { should belong_to(:patient) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:remind_on) }
    it { should validate_presence_of(:message) }
  end
end
