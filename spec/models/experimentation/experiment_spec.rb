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

    it "there can only be one live experiment of a particular type at a time" do
      create(:experiment, state: :live, experiment_type: "current_patient_reminder")
      create(:experiment, state: :live, experiment_type: "inactive_patient_reminder")

      experiment_3 = build(:experiment, state: :live, experiment_type: "current_patient_reminder")
      expect(experiment_3).to be_invalid

      experiment_4 = build(:experiment, state: :live, experiment_type: "inactive_patient_reminder")
      expect(experiment_4).to be_invalid
    end

    it "can only be updated to a complete and valid date range" do
      experiment = create(:experiment)
      experiment.update(start_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: nil, end_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: Date.today + 3.days, end_date: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_date: Date.today, end_date: Date.today + 3.days)
      expect(experiment).to be_valid
    end
  end
end
