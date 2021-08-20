require "rails_helper"

RSpec.describe Experimentation::Experiment, type: :model do
  let(:experiment) { create(:experiment) }

  describe "associations" do
    it { should have_many(:treatment_groups) }
    it { should have_many(:patients).through(:treatment_groups) }
    it { should have_many(:reminder_templates).through(:treatment_groups) }
    it { should have_many(:notifications) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { experiment.should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:experiment_type) }

    it "there can only be one active experiment of a particular type at a time" do
      create(:experiment, state: :running, experiment_type: "current_patients")
      create(:experiment, state: :selecting, experiment_type: "stale_patients")

      experiment_3 = build(:experiment, state: :running, experiment_type: "current_patients")
      expect(experiment_3).to be_invalid

      experiment_4 = build(:experiment, state: :running, experiment_type: "stale_patients")
      expect(experiment_4).to be_invalid
    end

    it "can only be updated to a complete and valid date range" do
      experiment = create(:experiment)
      experiment.update(start_date: Date.today, end_date: nil)
      expect(experiment).to be_invalid
      experiment.update(start_date: nil, end_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: Date.today + 3.days, end_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: Date.today, end_date: Date.today + 3.days)
      expect(experiment).to be_valid
    end

    it "only allows one instance of type 'medication_reminder'" do
      _existing = create(:experiment, experiment_type: "medication_reminder")
      expect(build(:experiment, experiment_type: "medication_reminder")).to be_invalid
    end
  end

  describe "#random_treatment_group" do
    it "returns a treatment group from the experiment" do
      experiment1 = create(:experiment, :with_treatment_group)
      experiment2 = create(:experiment, :with_treatment_group)

      expect(experiment1.random_treatment_group).to eq(experiment1.treatment_groups.first)
      expect(experiment2.random_treatment_group).to eq(experiment2.treatment_groups.first)
    end
  end
end
