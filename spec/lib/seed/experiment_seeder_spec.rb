require "rails_helper"

RSpec.describe Seed::ExperimentSeeder do
  describe ".create_current_experiment" do
    it "creates experiment, treatment groups, and reminder templates" do
      expect(Experimentation::Experiment.count).to eq(0)
      expect(Experimentation::TreatmentGroup.count).to eq(0)
      expect(Experimentation::ReminderTemplate.count).to eq(0)
      described_class.create_current_experiment
      expect(Experimentation::Experiment.count).to eq(1)
      expect(Experimentation::TreatmentGroup.count).to eq(3)
      expect(Experimentation::ReminderTemplate.count).to eq(4)
    end
  end

  describe ".create_stale_experiment" do
    it "creates experiment, treatment groups, and reminder templates" do
      expect(Experimentation::Experiment.count).to eq(0)
      expect(Experimentation::TreatmentGroup.count).to eq(0)
      expect(Experimentation::ReminderTemplate.count).to eq(0)
      described_class.create_stale_experiment(start_date: 1.day.from_now, end_date: 2.days.from_now)
      expect(Experimentation::Experiment.count).to eq(1)
      expect(Experimentation::TreatmentGroup.count).to eq(3)
      expect(Experimentation::ReminderTemplate.count).to eq(3)
    end
  end
end
