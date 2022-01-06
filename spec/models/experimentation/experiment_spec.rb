# frozen_string_literal: true

require "rails_helper"

RSpec.describe Experimentation::Experiment, type: :model do
  let(:experiment) { create(:experiment) }

  describe "associations" do
    it { should have_many(:treatment_groups) }
    it { should have_many(:patients).through(:treatment_groups) }
    it { should have_many(:reminder_templates).through(:treatment_groups) }
    it { should have_many(:notifications) }
  end

  describe "scopes" do
    context "experiment state" do
      specify do
        running = create(:experiment, :running)
        upcoming = create(:experiment, :upcoming)
        monitoring = create(:experiment, :monitoring)
        completed = create(:experiment, :completed)
        cancelled = create(:experiment, :cancelled, start_time: 5.months.ago, end_time: 4.months.ago)

        expect(described_class.running).to contain_exactly(running)
        expect(described_class.upcoming).to contain_exactly(upcoming)
        expect(described_class.monitoring).to contain_exactly(running, monitoring)
        expect(described_class.completed).to contain_exactly(completed)
        expect(described_class.cancelled).to contain_exactly(cancelled)
      end
    end
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { experiment.should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:experiment_type) }

    it "there can only be one active experiment of a particular type at a time" do
      create(:experiment, :running, experiment_type: "current_patients")
      create(:experiment, :running, experiment_type: "stale_patients")

      experiment_3 = build(:experiment, :running, experiment_type: "current_patients")
      expect(experiment_3).to be_invalid

      experiment_4 = build(:experiment, :running, experiment_type: "stale_patients")
      expect(experiment_4).to be_invalid
    end

    it "can only be updated to a complete and valid date range" do
      experiment = create(:experiment)
      experiment.update(start_time: Date.today, end_time: nil)
      expect(experiment).to be_invalid
      experiment.update(start_time: nil, end_time: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_time: Date.today + 3.days, end_time: Date.today)
      expect(experiment).to be_invalid
      experiment.update(start_time: Date.today, end_time: Date.today + 3.days)
      expect(experiment).to be_valid
    end

    it "should validate that start and end dates are present on the experiment" do
      experiment = build(:experiment, start_time: nil, end_time: nil)

      experiment.validate
      expect(experiment.errors[:start_time]).to be_present
      expect(experiment.errors[:end_time]).to be_present
    end

    it "should validate that start date is after the end date" do
      experiment = build(:experiment, start_time: Time.current, end_time: 10.days.ago)

      experiment.validate
      expect(experiment.errors[:date_range]).to be_present
    end

    describe "#one_active_experiment_per_type" do
      it "does not allow creating experiments with overlapping intervals of the same type" do
        _existing_experiment = create(:experiment, experiment_type: "current_patients", start_time: "10 Feb 2021", end_time: "20 Feb 2021")
        overlapping_intervals = [
          ["1 Feb 2021", "15 Feb 2021"],
          ["12 Feb 2021", "18 Feb 2021"],
          ["18 Feb 2021", "22 Feb 2021"],
          ["1 Feb 2021", "28 Feb 2021"]
        ]

        overlapping_intervals.each do |interval|
          experiment = build(:experiment, experiment_type: "current_patients", start_time: interval.first, end_time: interval.second)
          experiment.validate

          expect(experiment.errors[:state].first).to match(/you cannot have multiple active experiments/)
        end
      end

      it "allows creating experiments of the same type where intervals don't overlap" do
        _existing_experiment = create(:experiment, experiment_type: "current_patients", start_time: "10 Feb 2021", end_time: "20 Feb 2021")
        valid_intervals = [
          ["1 Feb 2021", "8 Feb 2021"],
          ["22 Feb 2021", "25 Feb 2021"]
        ]

        valid_intervals.each do |interval|
          experiment = build(:experiment, experiment_type: "current_patients", start_time: interval.first, end_time: interval.second)
          experiment.validate

          expect(experiment.errors[:state]).not_to be_present
        end
      end

      it "allows overlapping experiments of different types" do
        _existing_experiment = create(:experiment, experiment_type: "current_patients", start_time: "10 Feb 2021", end_time: "20 Feb 2021")
        overlapping_intervals = [
          ["1 Feb 2021", "15 Feb 2021"],
          ["12 Feb 2021", "18 Feb 2021"],
          ["18 Feb 2021", "22 Feb 2021"],
          ["1 Feb 2021", "28 Feb 2021"]
        ]

        overlapping_intervals.each do |interval|
          experiment = build(:experiment, experiment_type: "stale_patients", start_time: interval.first, end_time: interval.second)
          experiment.validate

          expect(experiment.errors[:state]).not_to be_present
        end
      end
    end
  end

  describe "#random_treatment_group" do
    it "returns a treatment group from the experiment" do
      experiment1 = create(:experiment, :with_treatment_group)
      experiment2 = create(:experiment, :with_treatment_group, start_time: 10.days.from_now, end_time: 20.days.from_now)

      expect(experiment1.random_treatment_group).to eq(experiment1.treatment_groups.first)
      expect(experiment2.random_treatment_group).to eq(experiment2.treatment_groups.first)
    end
  end

  describe "#cancel" do
    it "cancels the experiment" do
      experiment = create(:experiment)
      experiment.cancel

      expect(experiment.reload.deleted_at).to be_present
    end
  end
end
