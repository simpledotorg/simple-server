require "rails_helper"

RSpec.describe Seed::ExperimentSeeder do
  it "creates experiment, treatment groups, and reminder templates" do
    expect(Experimentation::Experiment.count).to eq(0)
    expect(Experimentation::TreatmentGroup.count).to eq(0)
    expect(Experimentation::ReminderTemplate.count).to eq(0)
    described_class.call
    expect(Experimentation::Experiment.count).to eq(1)
    expect(Experimentation::TreatmentGroup.count).to eq(3)
    expect(Experimentation::ReminderTemplate.count).to eq(3)
  end
end