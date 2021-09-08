require "rails_helper"

RSpec.describe Experimentation::ReminderTemplate, type: :model do
  describe "associations" do
    it { should belong_to(:treatment_group) }
    it { should have_many(:notifications) }
  end

  describe "validations" do
    it { should validate_presence_of(:message) }
    it { should validate_presence_of(:remind_on_in_days) }
    it { should validate_numericality_of(:remind_on_in_days) }
  end
end
