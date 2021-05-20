require "rails_helper"

describe ExperimentControlService, type: :model do
  describe "self.start_current_patient_experiment" do
    it "only selects from patients 18 and older" do
      young_patient = create(:patient, age: 17)
      old_patient = create(:patient, age: 18)
      create(:appointment, patient: young_patient, scheduled_date: 10.days.from_now)
      create(:appointment, patient: old_patient, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)

      expect(experiment.patients.include?(old_patient)).to be_truthy
      expect(experiment.patients.include?(young_patient)).to be_falsey
    end

    it "only selects hypertensive patients" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, :without_hypertension, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_falsey
    end

    it "only selects patients with mobile phones" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient1.phone_numbers.destroy_all
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
    end

    it "only selects from patients with appointments scheduled during the experiment date range" do
      days_til_start = 5
      days_til_end = 5

      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 4.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 6.days.from_now)
      patient3 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 5.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(experiment.name, days_til_start, days_til_end)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_falsey
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "excludes patients who have recently been in an experiment" do
      old_experiment = create(:experiment, :with_treatment_group, name: "old", start_date: 2.days.ago, end_date: 1.day.ago)
      old_group = old_experiment.treatment_groups.first

      older_experiment = create(:experiment, :with_treatment_group, name: "older", start_date: 16.days.ago, end_date: 15.day.ago)
      older_group = older_experiment.treatment_groups.first

      patient1 = create(:patient, age: 80)
      old_group.treatment_group_memberships.create!(patient: patient1)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)

      patient2 = create(:patient, age: 80)
      older_group.treatment_group_memberships.create!(patient: patient2)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      patient3 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "only includes the specified percentage of eligible patients" do
      percentage = 50
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35, percentage)

      expect(experiment.patients.count).to eq(1)
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:appointment, patient: patient, scheduled_date: 10.days.from_now)
      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)

      expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
    end

    it "adds reminders for all appointments scheduled in the date range and not for appointments outside the range" do
      patient = create(:patient, age: 80)
      old_appointment = create(:appointment, patient: patient, scheduled_date: 10.days.ago)
      far_future_appointment = create(:appointment, patient: patient, scheduled_date: 100.days.from_now)
      upcoming_appointment1 = create(:appointment, patient: patient, scheduled_date: 10.days.from_now)
      upcoming_appointment2 = create(:appointment, patient: patient, scheduled_date: 20.days.from_now)

      experiment = create(:experiment, :with_treatment_group)
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)

      reminder1 = Notification.find_by(patient: patient, subject: upcoming_appointment1)
      expect(reminder1).to be_truthy
      reminder2 = Notification.find_by(patient: patient, subject: upcoming_appointment2)
      expect(reminder2).to be_truthy
      unexpected_reminder1 = Notification.find_by(patient: patient, subject: old_appointment)
      expect(unexpected_reminder1).to be_falsey
      unexpected_reminder2 = Notification.find_by(patient: patient, subject: far_future_appointment)
      expect(unexpected_reminder2).to be_falsey
    end

    it "schedules cascading reminders based on reminder templates" do
      patient1 = create(:patient, age: 80)
      appointment_date = 10.days.from_now.to_date
      create(:appointment, patient: patient1, scheduled_date: appointment_date)

      experiment = create(:experiment, :with_treatment_group)
      group = experiment.treatment_groups.first

      create(:reminder_template, treatment_group: group, message: "come in 3 days", remind_on_in_days: -3)
      create(:reminder_template, treatment_group: group, message: "come today", remind_on_in_days: 0)
      create(:reminder_template, treatment_group: group, message: "you're late", remind_on_in_days: 3)

      ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)

      reminder1, reminder2, reminder3 = patient1.notifications.sort_by { |ar| ar.remind_on }
      expect(reminder1.remind_on).to eq(appointment_date - 3.days)
      expect(reminder2.remind_on).to eq(appointment_date)
      expect(reminder3.remind_on).to eq(appointment_date + 3.days)
    end

    it "updates the experiment state, start date, and end date" do
      days_til_start = 5
      days_til_end = 35
      experiment = create(:experiment)
      ExperimentControlService.start_current_patient_experiment(experiment.name, days_til_start, days_til_end)
      experiment.reload

      expect(experiment).to be_running_state
      expect(experiment.start_date).to eq(days_til_start.days.from_now.to_date)
      expect(experiment.end_date).to eq(days_til_end.days.from_now.to_date)
    end

    it "does not create appointment reminders or update the experiment if there's another experiment of the same type in progress" do
      experiment = create(:experiment)
      create(:experiment, state: "selecting")
      expect {
        ExperimentControlService.start_current_patient_experiment(experiment.name, 5, 35)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Notification.count).to eq(0)
      expect(experiment.reload.state).to eq("new")
    end

    it "raises an error if the days_til_end is less than days_til_start" do
      experiment = create(:experiment)

      expect {
        ExperimentControlService.start_current_patient_experiment(experiment.name, 35, 5)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "self.start_stale_patient_experiment" do
    it "excludes patients who have recently been in an experiment" do
      old_experiment = create(:experiment, :with_treatment_group, name: "old", start_date: 2.days.ago, end_date: 1.day.ago)
      old_group = old_experiment.treatment_groups.first

      older_experiment = create(:experiment, :with_treatment_group, name: "older", start_date: 16.days.ago, end_date: 15.day.ago)
      older_group = older_experiment.treatment_groups.first

      patient1 = create(:patient, age: 80)
      old_group.treatment_group_memberships.create!(patient: patient1)
      create(:blood_sugar, patient: patient1, device_created_at: 100.days.ago)

      patient2 = create(:patient, age: 80)
      older_group.treatment_group_memberships.create!(patient: patient2)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)

      patient3 = create(:patient, age: 80)
      create(:prescription_drug, patient: patient3, device_created_at: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      ExperimentControlService.start_stale_patient_experiment(experiment.name)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:blood_pressure, patient: patient, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      ExperimentControlService.start_stale_patient_experiment(experiment.name)

      expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
    end

    it "creates notifications for selected patients" do
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect {
        ExperimentControlService.start_stale_patient_experiment(experiment.name)
      }.to change { patient1.notifications.count }.by(1)
    end

    it "schedules cascading reminders based on reminder templates" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, device_created_at: 100.days.ago, scheduled_date: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      group = experiment.treatment_groups.first
      create(:reminder_template, treatment_group: group, message: "come today", remind_on_in_days: 0)
      create(:reminder_template, treatment_group: group, message: "you're late", remind_on_in_days: 3)

      ExperimentControlService.start_stale_patient_experiment(experiment.name)

      today = Date.current
      reminder1, reminder2 = patient1.notifications.sort_by { |ar| ar.remind_on }
      expect(reminder1.remind_on).to eq(today)
      expect(reminder2.remind_on).to eq(today + 3.days)
    end

    it "updates the experiment state" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      ExperimentControlService.start_stale_patient_experiment(experiment.name)
      experiment.reload

      expect(experiment).to be_running_state
    end

    it "does not create appointment reminders or update the experiment if there's another experiment of the same type in progress" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      create(:experiment, experiment_type: "stale_patients", state: "selecting")
      expect {
        ExperimentControlService.start_stale_patient_experiment(experiment.name)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Notification.count).to eq(0)
      expect(experiment.reload.state).to eq("new")
    end

    it "only schedules reminders for PATIENTS_PER_DAY by default" do
      stub_const("ExperimentControlService::PATIENTS_PER_DAY", 1)
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      patient2 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      expect {
        ExperimentControlService.start_stale_patient_experiment(experiment.name)
      }.to change { Experimentation::TreatmentGroupMembership.count }.by(1)
    end

    it "limits participants to patients_per_day if provided" do
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      patient2 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      expect {
        ExperimentControlService.start_stale_patient_experiment(experiment.name, patients_per_day: 1)
      }.to change { Experimentation::TreatmentGroupMembership.count }.by(1)
    end
  end
end
