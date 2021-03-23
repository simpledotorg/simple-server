require "rails_helper"

RSpec.describe Experiment::ReminderExperiment, type: :model do
  describe "associations" do
    it { should have_many(:reminder_templates) }
  end

  describe "validations" do
    it { should validate_presence_of(:active) }
  end
end
