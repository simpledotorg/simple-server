require "rails_helper"

describe Experimentation::RunnerV2, type: :model do
  describe ".call" do
    before { Flipper.enable(:experiment) }

    it "does not add patients, or create notifications if the feature flag is off" do
      Flipper.disable(:experiment)

      patient1 = create(:patient, age: 80)
      create(:blood_sugar, patient: patient1, device_created_at: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.call

      expect(experiment.patients.count).to eq(0)
      expect(experiment.notifications.count).to eq(0)
    end

    it "excludes patients who have recently been in an experiment" do
      recent_experiment = create(:experiment, :with_treatment_group, name: "old", start_time: 2.days.ago, end_time: 1.day.ago)

      old_experiment = create(:experiment, :with_treatment_group, name: "older", start_time: 16.days.ago, end_time: 15.day.ago)
      old_experiment.treatment_groups.first

      patient1 = create(:patient, age: 80)
      recent_experiment.treatment_groups.first.enroll(patient1)
      create(:blood_sugar, patient: patient1, device_created_at: 100.days.ago)

      patient2 = create(:patient, age: 80)
      old_experiment.treatment_groups.first.enroll(patient2)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)

      patient3 = create(:patient, age: 80)
      create(:prescription_drug, patient: patient3, device_created_at: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      described_class.call

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:blood_pressure, patient: patient, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      described_class.call

      expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
    end

  end
end
