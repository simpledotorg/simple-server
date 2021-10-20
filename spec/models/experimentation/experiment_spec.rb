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

  describe ".candidate_patients" do
    it "doesn't include patients from a running experiment" do
      experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      treatment_group = create(:treatment_group, experiment: experiment)

      patient = create(:patient, age: 18)
      not_enrolled_patient = create(:patient, age: 18)

      treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
      expect(described_class.candidate_patients).to include(not_enrolled_patient)
    end

    it "includes patients from experiments that ended before 14 days" do
      experiment = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient, age: 18)
      treatment_group.enroll(patient)

      expect(described_class.candidate_patients).to include(patient)
    end

    it "doesn't include patients from experiments that ended within 14 days" do
      experiment = create(:experiment, start_time: 30.days.ago, end_time: 10.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient, age: 18)
      treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "doesn't include patients are in a future experiment" do
      future_experiment = create(:experiment, start_time: 10.days.from_now, end_time: 20.days.from_now)
      future_treatment_group = create(:treatment_group, experiment: future_experiment)

      patient = create(:patient, age: 18)

      future_treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "doesn't include patients who were once in a completed experiment but are now in a running experiment" do
      running_experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      old_experiment = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      running_treatment_group = create(:treatment_group, experiment: running_experiment)
      old_treatment_group = create(:treatment_group, experiment: old_experiment)

      patient = create(:patient, age: 18)

      old_treatment_group.enroll(patient)
      running_treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "doesn't include patients twice if they were in multiple experiments that ended" do
      experiment_1 = create(:experiment, start_time: 10.days.ago, end_time: 5.days.ago)
      experiment_2 = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      treatment_group_1 = create(:treatment_group, experiment: experiment_1)
      treatment_group_2 = create(:treatment_group, experiment: experiment_2)

      patient = create(:patient, age: 18)

      treatment_group_1.enroll(patient)
      treatment_group_2.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "excludes any patients who have multiple scheduled appointments" do
      excluded_patient = create(:patient, age: 18)
      create_list(:appointment, 2, patient: excluded_patient, status: :scheduled)

      included_patient = create(:patient, age: 18)
      create(:appointment, patient: included_patient, status: :scheduled)

      expect(described_class.candidate_patients).not_to include(excluded_patient)
      expect(described_class.candidate_patients).to include(included_patient)
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

  describe "#abort" do
    it "changes pending and scheduled notification statuses to 'cancelled'" do
      experiment = create(:experiment)
      patient = create(:patient)

      pending_notification = create(:notification, experiment: experiment, patient: patient, status: "pending")
      scheduled_notification = create(:notification, experiment: experiment, patient: patient, status: "scheduled")
      sent_notification = create(:notification, experiment: experiment, patient: patient, status: "sent")

      experiment.abort

      expect(pending_notification.reload.status).to eq("cancelled")
      expect(scheduled_notification.reload.status).to eq("cancelled")
      expect(sent_notification.reload.status).to eq("sent")
    end
  end

end
