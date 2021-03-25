require "rails_helper"

RSpec.describe Experimentation::ReminderTemplate, type: :model do
  describe "associations" do
    it { should belong_to(:treatment_cohort) }
    it { should have_many(:appointment_reminders) }
  end

  describe "validations" do
    it { should validate_presence_of(:message) }
    it { should validate_presence_of(:appointment_offset) }
  end
end
