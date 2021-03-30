require "rails_helper"

describe ExperimentControlService, type: :model do
  describe "self.start_current_patient_experiment" do
    it "only selects from patients 18 and older" do
      young_patient = create(:patient, age: 17)
      old_patient = create(:patient, age: 18)
      create(:appointment, patient: young_patient, scheduled_date: 10.days.from_now)
      create(:appointment, patient: old_patient, scheduled_date: 10.days.from_now)

      experiment = create(:experiment)
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 100)

      expect(experiment.patients.include?(old_patient)).to be_truthy
      expect(group.patients.include?(old_patient)).to be_truthy
      expect(experiment.patients.include?(young_patient)).to be_falsey
      expect(group.patients.include?(young_patient)).to be_falsey
    end

    it "only selects hypertensive patients" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, :without_hypertension, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment)
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 100)

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(group.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_falsey
      expect(group.patients.include?(patient2)).to be_falsey
    end

    it "only selects patients with mobile phones" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient1.phone_numbers.destroy_all
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment)
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 100)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(group.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(group.patients.include?(patient2)).to be_truthy
    end

    it "only selects from patients with appointments scheduled during the experiment date range" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: Date.current)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 40.days.from_now)
      patient3 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 5.days.from_now)

      experiment = create(:experiment)
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 100, 5)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(group.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_falsey
      expect(group.patients.include?(patient2)).to be_falsey
      expect(experiment.patients.include?(patient3)).to be_truthy
      expect(group.patients.include?(patient3)).to be_truthy
    end

    it "only selects the provided percentage of eligible patients" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment)
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 50)

      expect(experiment.patients.count).to eq(1)
      expect(group.patients.count).to eq(1)
    end

    it "adds reminders for currently scheduled appointments" do
      patient = create(:patient, age: 80)
      create(:appointment, patient: patient, scheduled_date: 10.days.from_now)

      experiment = create(:experiment)
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 100)

      membership = Experimentation::TreatmentGroupMembership.find_by(patient_id: patient.id, treatment_group_id: group.id)
      expect(membership).to be_truthy
    end

    it "buckets patients according to id" do
    end

    it "schedules cascading reminders" do
    end

    it "updates the experiment state and start date" do
      experiment = create(:experiment)
      ExperimentControlService.start_current_patient_experiment(experiment.name, 100, 5)
      expect(experiment.reload.state).to eq("live")
      expect(experiment.start_date).to eq(Date.current + 5.days)
    end
  end

  describe "self.start_stale_patient_experiment" do
    it "only selects from patients 18 and older" do
      young_patient = create(:patient, age: 17)
      old_patient = create(:patient, age: 18)
      create(:appointment, patient: young_patient, scheduled_date: 100.days.ago)
      create(:appointment, patient: old_patient, scheduled_date: 100.days.ago)

      experiment = create(:experiment, experiment_type: "stale_patient_reminder")
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_stale_patient_experiment(experiment.name, 100)

      expect(experiment.patients.include?(old_patient)).to be_truthy
      expect(group.patients.include?(old_patient)).to be_truthy
      expect(experiment.patients.include?(young_patient)).to be_falsey
      expect(group.patients.include?(young_patient)).to be_falsey
    end

    it "only selects hypertensive patients" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 100.days.ago)
      patient2 = create(:patient, :without_hypertension, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 100.days.ago)

      experiment = create(:experiment, experiment_type: "stale_patient_reminder")
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_stale_patient_experiment(experiment.name, 100)

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(group.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_falsey
      expect(group.patients.include?(patient2)).to be_falsey
    end

    it "only selects patients with mobile phones" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 100.days.ago)
      patient1.phone_numbers.destroy_all
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 100.days.ago)

      experiment = create(:experiment, experiment_type: "stale_patient_reminder")
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_stale_patient_experiment(experiment.name, 100)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(group.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(group.patients.include?(patient2)).to be_truthy
    end
  end
end
