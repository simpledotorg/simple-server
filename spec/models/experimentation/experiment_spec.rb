require "rails_helper"

RSpec.describe Experimentation::Experiment, type: :model do
  let(:experiment) { create(:experiment) }

  describe "associations" do
    it { should have_many(:treatment_groups) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { experiment.should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:experiment_type) }

    it "there can only be one live experiment at a time" do
      experiment_1 = create(:experiment, state: :live, experiment_type: "current_patient_reminder")
      experiment_2 = create(:experiment, state: :live, experiment_type: "stale_patient_reminder")

      experiment_3 = build(:experiment, state: :live, experiment_type: "current_patient_reminder")
      expect(experiment_3).to be_invalid

      experiment_4 = build(:experiment, state: :live, experiment_type: "stale_patient_reminder")
      expect(experiment_4).to be_invalid
    end
  end
end
