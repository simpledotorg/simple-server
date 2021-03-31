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

    it "excludes patients who have recently received an experimental reminder" do
      old_experiment = create(:experiment, name: "old", end_date: 2.days.ago)
      old_group = create(:treatment_group, experiment: old_experiment, index: 0)

      patient1 = create(:patient, age: 80)
      old_group.treatment_group_memberships.create!(patient: patient1)

      appointment1 = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      reminder = create(:appointment_reminder, patient: patient1, experiment: old_experiment, appointment: appointment1, remind_on: 10.day.from_now)
      patient2 = create(:patient, age: 80)
      # old_group.treatment_group_memberships.create!(patient: patient2)
      appointment2 = create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)
      # reminder = create(:appointment_reminder, patient: patient2, experiment: old_experiment, appointment: appointment2, remind_on: 15.days.ago)
      patient3 = create(:patient, age: 80)
      appointment3 = create(:appointment, patient: patient3, scheduled_date: 10.days.from_now)

      experiment = create(:experiment)
      group = create(:treatment_group, experiment: experiment, index: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 100)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
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

    it "adds patients to treatment groups predictably based on patient id" do
      patient1 = create(:patient, age: 80, id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, age: 80, id: "aaaaaaaa-bbbb-cccc-dddd-ffffffffffff")
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment)
      group1 = create(:treatment_group, experiment: experiment, index: 0)
      group2 = create(:treatment_group, experiment: experiment, index: 1)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 100)

      expect(group1.patients.include?(patient2)).to be_truthy
      expect(group2.patients.include?(patient1)).to be_truthy
    end

    it "schedules cascading reminders" do
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
    end

    it "updates the experiment state and start date" do
      experiment = create(:experiment)
      ExperimentControlService.start_current_patient_experiment(experiment.name, 100, 5)
      expect(experiment.reload.state).to eq("live")
      expect(experiment.start_date).to eq(Date.current + 5.days)
    end

    it "raises an error if an another experiment is already in progress" do
      experiment = create(:experiment)
      other_experiment = create(:experiment, state: "selecting")

      expect {
        ExperimentControlService.start_current_patient_experiment(experiment.name, 100, 5)
      }.to raise_error(InvalidExperiment)

      other_experiment.state_live!

      expect {
        ExperimentControlService.start_current_patient_experiment(experiment.name, 100, 5)
      }.to raise_error(InvalidExperiment)

      other_experiment.state_complete!

      expect {
        ExperimentControlService.start_current_patient_experiment(experiment.name, 100, 5)
      }.not_to raise_error(InvalidExperiment)
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

      ExperimentControlService.start_stale_patient_experiment(experiment.name)

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

      ExperimentControlService.start_stale_patient_experiment(experiment.name)

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

      ExperimentControlService.start_stale_patient_experiment(experiment.name)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(group.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(group.patients.include?(patient2)).to be_truthy
    end
  end
end
