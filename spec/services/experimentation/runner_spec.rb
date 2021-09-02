require "rails_helper"

describe Experimentation::Runner, type: :model do
  include ActiveJob::TestHelper

  describe "self.start_current_patient_experiment" do
    before { Flipper.enable(:experiment) }

    it "does not start the experiment, add patients, or create notifications if the feature flag is off" do
      Flipper.disable(:experiment)

      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "current_patients", start_date: 5.days.from_now, end_date: 35.days.from_now)
      _template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.start_current_patient_experiment(name: experiment.name)

      expect(experiment.reload.state).to eq("new")
      expect(experiment.patients.count).to eq(0)
      expect(experiment.notifications.count).to eq(0)
    end

    it "only selects from patients 18 and older" do
      young_patient = create(:patient, age: 17)
      old_patient = create(:patient, age: 18)
      create(:appointment, patient: young_patient, scheduled_date: 10.days.from_now)
      create(:appointment, patient: old_patient, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)

      described_class.start_current_patient_experiment(name: experiment.name)

      expect(experiment.patients.include?(old_patient)).to be_truthy
      expect(experiment.patients.include?(young_patient)).to be_falsey
    end

    it "only selects hypertensive patients" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, :without_hypertension, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)

      described_class.start_current_patient_experiment(name: experiment.name)

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_falsey
    end

    it "only selects patients with mobile phones" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient1.phone_numbers.destroy_all
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)

      described_class.start_current_patient_experiment(name: experiment.name)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
    end

    it "only selects from patients with appointments scheduled during the experiment date range" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 4.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 6.days.from_now)
      patient3 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 5.days.from_now)

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 5.days.from_now)

      described_class.start_current_patient_experiment(name: experiment.name)

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

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)

      described_class.start_current_patient_experiment(name: experiment.name)

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

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)

      described_class.start_current_patient_experiment(name: experiment.name, percentage_of_patients: percentage)

      expect(experiment.patients.count).to eq(1)
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:appointment, patient: patient, scheduled_date: 10.days.from_now)
      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)

      described_class.start_current_patient_experiment(name: experiment.name)

      expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
    end

    it "adds reminders for all appointments scheduled in the date range and not for appointments outside the range" do
      patient = create(:patient, age: 80)
      old_appointment = create(:appointment, patient: patient, scheduled_date: 10.days.ago)
      far_future_appointment = create(:appointment, patient: patient, scheduled_date: 100.days.from_now)
      upcoming_appointment1 = create(:appointment, patient: patient, scheduled_date: 10.days.from_now)
      upcoming_appointment2 = create(:appointment, patient: patient, scheduled_date: 20.days.from_now)

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.start_current_patient_experiment(name: experiment.name)

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

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)
      group = experiment.treatment_groups.first

      create(:reminder_template, treatment_group: group, message: "come in 3 days", remind_on_in_days: -3)
      create(:reminder_template, treatment_group: group, message: "come today", remind_on_in_days: 0)
      create(:reminder_template, treatment_group: group, message: "you're late", remind_on_in_days: 3)

      described_class.start_current_patient_experiment(name: experiment.name)

      reminder1, reminder2, reminder3 = patient1.notifications.sort_by { |ar| ar.remind_on }
      expect(reminder1.remind_on).to eq(appointment_date - 3.days)
      expect(reminder2.remind_on).to eq(appointment_date)
      expect(reminder3.remind_on).to eq(appointment_date + 3.days)
    end

    it "only creates a notification for scheduled appointments during the window" do
      patient1 = create(:patient, age: 80)
      scheduled_appointment = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now, status: "scheduled")
      visited_appointment = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now, status: "visited")
      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.start_current_patient_experiment(name: experiment.name)

      expect(scheduled_appointment.notifications.count).to eq 1
      expect(visited_appointment.notifications.count).to eq 0
    end

    it "creates experimental reminder notifications with correct attributes" do
      patient1 = create(:patient, age: 80)
      appointment = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)
      template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect {
        described_class.start_current_patient_experiment(name: experiment.name)
      }.to change { patient1.notifications.count }.by(1)
      notification = patient1.notifications.last
      expect(notification.remind_on).to eq(appointment.scheduled_date)
      expect(notification.purpose).to eq("experimental_appointment_reminder")
      expect(notification.message).to eq(template.message)
      expect(notification.status).to eq("pending")
      expect(notification.reminder_template).to eq(template)
      expect(notification.subject).to eq(appointment)
      expect(notification.experiment).to eq(experiment)
    end

    it "updates the experiment state to 'running'" do
      experiment = create(:experiment, start_date: 5.days.from_now, end_date: 35.days.from_now)
      expect {
        described_class.start_current_patient_experiment(name: experiment.name)
      }.to change { experiment.reload.state }.to("running")

      expect(experiment).to be_running_state
    end

    it "does nothing if the experiment is in 'running' state" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      experiment = create(:experiment, :with_treatment_group, state: "running", start_date: 5.days.from_now, end_date: 35.days.from_now)
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect { described_class.start_current_patient_experiment(name: experiment.name) }
        .to not_change { experiment.reload.state }
        .and not_change { Notification.count }
    end

    it "marks the experiment complete if the end date has passed" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.ago)
      experiment = create(:experiment, :with_treatment_group, state: "running", start_date: 20.days.ago, end_date: 1.days.ago)
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect {
        described_class.start_current_patient_experiment(name: experiment.name)
      }.to change { experiment.reload.state }.from("running").to("complete")
        .and not_change { Notification.count }
    end

    it "raises a sentry error if the experiment is not found" do
      expect(described_class.logger).to receive(:info).with(/Experiment UNKNOWN not found and may need to be removed/)
      described_class.start_current_patient_experiment(name: "UNKNOWN")
    end
  end

  describe "self.extend_current_patient_experiment" do
    before { Flipper.enable(:experiment) }

    it "does not add patients, or create notifications if the feature flag is off" do
      Flipper.disable(:experiment)

      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 38.days.from_now)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "current_patients", start_date: 5.days.from_now, end_date: 35.days.from_now)
      extended_end_date = 40.days.from_now
      _template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.count).to eq(0)
      expect(experiment.notifications.count).to eq(0)
    end

    it "does not add patients, or create notifications if the experiment is not running" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        experiment_type: "current_patients",
        state: "new",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now
      _template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.count).to eq(0)
      expect(experiment.notifications.count).to eq(0)
    end

    it "does not add patients, or create notifications if the extended end date is on or before the current end date" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 32.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 30.days.from_now

      expect(described_class.logger).to receive(:info).with(/must be later than existing end date/)

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.count).to eq(0)
      expect(experiment.notifications.count).to eq(0)
    end

    it "only selects from patients 18 and older" do
      young_patient = create(:patient, age: 17)
      old_patient = create(:patient, age: 18)
      create(:appointment, patient: young_patient, scheduled_date: 38.days.from_now)
      create(:appointment, patient: old_patient, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.include?(old_patient)).to be_truthy
      expect(experiment.patients.include?(young_patient)).to be_falsey
    end

    it "only selects hypertensive patients" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 38.days.from_now)
      patient2 = create(:patient, :without_hypertension, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_falsey
    end

    it "only selects patients with mobile phones" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 38.days.from_now)
      patient1.phone_numbers.destroy_all
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
    end

    it "only selects from patients with appointments scheduled during the extended date range" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 35.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 36.days.from_now)
      patient3 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 40.days.from_now)
      patient4 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 41.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
      expect(experiment.patients.include?(patient4)).to be_falsey
    end

    it "excludes patients who have recently been in an experiment" do
      old_experiment = create(:experiment, :with_treatment_group, name: "old", start_date: 2.days.ago, end_date: 1.day.ago)
      old_group = old_experiment.treatment_groups.first

      older_experiment = create(:experiment, :with_treatment_group, name: "older", start_date: 16.days.ago, end_date: 15.day.ago)
      older_group = older_experiment.treatment_groups.first

      patient1 = create(:patient, age: 80)
      old_group.treatment_group_memberships.create!(patient: patient1)
      create(:appointment, patient: patient1, scheduled_date: 38.days.from_now)

      patient2 = create(:patient, age: 80)
      older_group.treatment_group_memberships.create!(patient: patient2)
      create(:appointment, patient: patient2, scheduled_date: 38.days.from_now)

      patient3 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "only includes the specified percentage of eligible patients" do
      percentage = 50
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 38.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date, percentage_of_patients: percentage)

      expect(experiment.patients.count).to eq(1)
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:appointment, patient: patient, scheduled_date: 38.days.from_now)
      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
    end

    it "adds reminders for all appointments scheduled strictly in the extension date range" do
      patient = create(:patient, age: 80)
      old_appointment = create(:appointment, patient: patient, scheduled_date: 10.days.ago)
      original_range_appointment = create(:appointment, patient: patient, scheduled_date: 10.days.from_now)
      far_future_appointment = create(:appointment, patient: patient, scheduled_date: 100.days.from_now)
      upcoming_appointment1 = create(:appointment, patient: patient, scheduled_date: 37.days.from_now)
      upcoming_appointment2 = create(:appointment, patient: patient, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      reminder1 = Notification.find_by(patient: patient, subject: upcoming_appointment1)
      expect(reminder1).to be_truthy
      reminder2 = Notification.find_by(patient: patient, subject: upcoming_appointment2)
      expect(reminder2).to be_truthy
      unexpected_reminder1 = Notification.find_by(patient: patient, subject: old_appointment)
      expect(unexpected_reminder1).to be_falsey
      unexpected_reminder2 = Notification.find_by(patient: patient, subject: original_range_appointment)
      expect(unexpected_reminder2).to be_falsey
      unexpected_reminder3 = Notification.find_by(patient: patient, subject: far_future_appointment)
      expect(unexpected_reminder3).to be_falsey
    end

    it "schedules cascading reminders based on reminder templates" do
      patient1 = create(:patient, age: 80)
      appointment_date = 38.days.from_now.to_date
      create(:appointment, patient: patient1, scheduled_date: appointment_date)

      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      group = experiment.treatment_groups.first
      extended_end_date = 40.days.from_now

      create(:reminder_template, treatment_group: group, message: "come in 3 days", remind_on_in_days: -3)
      create(:reminder_template, treatment_group: group, message: "come today", remind_on_in_days: 0)
      create(:reminder_template, treatment_group: group, message: "you're late", remind_on_in_days: 3)

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      reminder1, reminder2, reminder3 = patient1.notifications.sort_by { |ar| ar.remind_on }
      expect(reminder1.remind_on).to eq(appointment_date - 3.days)
      expect(reminder2.remind_on).to eq(appointment_date)
      expect(reminder3.remind_on).to eq(appointment_date + 3.days)
    end

    it "creates a notification for only scheduled appointments during the window" do
      patient1 = create(:patient, age: 80)
      scheduled_appointment = create(:appointment, patient: patient1, scheduled_date: 38.days.from_now, status: "scheduled")
      visited_appointment = create(:appointment, patient: patient1, scheduled_date: 38.days.from_now, status: "visited")
      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)
      extended_end_date = 40.days.from_now

      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(scheduled_appointment.notifications.count).to eq 1
      expect(visited_appointment.notifications.count).to eq 0
    end

    it "creates experimental reminder notifications with correct attributes" do
      patient1 = create(:patient, age: 80)
      appointment = create(:appointment, patient: patient1, scheduled_date: 38.days.from_now)
      experiment = create(
        :experiment,
        :with_treatment_group,
        :running,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)
      extended_end_date = 40.days.from_now

      expect {
        described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)
      }.to change { patient1.notifications.count }.by(1)
      notification = patient1.notifications.last
      expect(notification.remind_on).to eq(appointment.scheduled_date)
      expect(notification.purpose).to eq("experimental_appointment_reminder")
      expect(notification.message).to eq(template.message)
      expect(notification.status).to eq("pending")
      expect(notification.reminder_template).to eq(template)
      expect(notification.subject).to eq(appointment)
      expect(notification.experiment).to eq(experiment)
    end

    it "does not affect existing patients in the experiment" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 15.days.from_now)
      patient3 = create(:patient, age: 80)
      create(:appointment, patient: patient3, scheduled_date: 38.days.from_now)

      experiment = create(:experiment, :with_treatment_group, start_date: 5.days.from_now, end_date: 35.days.from_now)
      extended_end_date = 40.days.from_now

      # Include patients into the original experiment window
      described_class.start_current_patient_experiment(name: experiment.name)

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_falsey

      # Extend the experiment, ensure original patients are still there
      described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "does not affect existing notifications in the experiment" do
      patient1 = create(:patient, age: 80)
      _appointment = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 38.days.from_now)

      experiment = create(
        :experiment,
        :with_treatment_group,
        experiment_type: "current_patients",
        start_date: 5.days.from_now,
        end_date: 35.days.from_now
      )
      _template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)
      extended_end_date = 40.days.from_now

      # Include patients into the original experiment window
      described_class.start_current_patient_experiment(name: experiment.name)

      notification = patient1.notifications.last
      expect(notification).to be_present

      # Extend the experiment, ensure original notifications are still there
      expect {
        described_class.extend_current_patient_experiment(name: experiment.name, end_date: extended_end_date)
      }.not_to change {
        notification.reload.attributes
      }

      expect(patient2.notifications.count).to eq(1)
    end

    it "logs an error if the experiment is not found" do
      expect(described_class.logger).to receive(:info).with(/Experiment UNKNOWN not available/)
      described_class.extend_current_patient_experiment(name: "UNKNOWN", end_date: 40.days.from_now)
    end
  end

  describe "self.schedule_daily_stale_patient_notifications" do
    before { Flipper.enable(:experiment) }

    it "does not start the experiment, add patients, or create notifications if the feature flag is off" do
      Flipper.disable(:experiment)

      patient1 = create(:patient, age: 80)
      create(:blood_sugar, patient: patient1, device_created_at: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.schedule_daily_stale_patient_notifications(name: experiment.name)

      expect(experiment.reload.state).to eq("new")
      expect(experiment.patients.count).to eq(0)
      expect(experiment.notifications.count).to eq(0)
    end

    it "excludes patients who have recently been in an experiment" do
      recent_experiment = create(:experiment, :with_treatment_group, name: "old", start_date: 2.days.ago, end_date: 1.day.ago)

      old_experiment = create(:experiment, :with_treatment_group, name: "older", start_date: 16.days.ago, end_date: 15.day.ago)
      old_experiment.treatment_groups.first

      patient1 = create(:patient, age: 80)
      recent_experiment.treatment_groups.first.patients << patient1
      create(:blood_sugar, patient: patient1, device_created_at: 100.days.ago)

      patient2 = create(:patient, age: 80)
      old_experiment.treatment_groups.first.patients << patient2
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)

      patient3 = create(:patient, age: 80)
      create(:prescription_drug, patient: patient3, device_created_at: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      described_class.schedule_daily_stale_patient_notifications(name: experiment.name)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:blood_pressure, patient: patient, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      described_class.schedule_daily_stale_patient_notifications(name: experiment.name)

      expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
    end

    it "creates experimental reminder notifications with correct attributes for selected patients" do
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      appointment = create(:appointment, patient: patient1, scheduled_date: 70.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect {
        described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to change { patient1.notifications.count }.by(1)
      notification = patient1.notifications.last
      expect(notification).to be_status_pending
      expect(notification.remind_on).to eq(Date.current)
      expect(notification.purpose).to eq("experimental_appointment_reminder")
      expect(notification.message).to eq(template.message)
      expect(notification.reminder_template).to eq(template)
      expect(notification.subject).to eq(appointment)
      expect(notification.experiment).to eq(experiment)
    end

    it "schedules cascading reminders based on reminder templates" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, device_created_at: 100.days.ago, scheduled_date: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      group = experiment.treatment_groups.first
      create(:reminder_template, treatment_group: group, message: "come today", remind_on_in_days: 0)
      create(:reminder_template, treatment_group: group, message: "you're late", remind_on_in_days: 3)

      described_class.schedule_daily_stale_patient_notifications(name: experiment.name)

      today = Date.current
      reminder1, reminder2 = patient1.notifications.sort_by { |ar| ar.remind_on }
      expect(reminder1.remind_on).to eq(today)
      expect(reminder2.remind_on).to eq(today + 3.days)
    end

    it "updates the experiment state" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
      experiment.reload

      expect(experiment).to be_running_state
    end

    it "does not create appointment reminders or update the experiment if there's another experiment of the same type in progress" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      create(:experiment, experiment_type: "stale_patients", state: "selecting")
      expect {
        described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to raise_error(ActiveRecord::RecordInvalid)
        .and not_change { Notification.count }
        .and not_change { experiment.reload.state }
    end

    it "does nothing if it the experiment is not in 'new' or 'running' state" do
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients", state: "complete")
      group = experiment.treatment_groups.first
      create(:reminder_template, treatment_group: group, message: "come today", remind_on_in_days: 0)
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, device_created_at: 100.days.ago, scheduled_date: 100.days.ago)

      expect {
        described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to not_change { experiment.reload }
        .and not_change { Notification.count }
    end

    it "logs a message if experiment doesn't exist" do
      expect(described_class.logger).to receive(:info).with("Experiment doesn't exist not found and may need to be removed from scheduler - exiting.")
      described_class.schedule_daily_stale_patient_notifications(name: "doesn't exist")
    end

    it "only schedules reminders for PATIENTS_PER_DAY by default" do
      stub_const("#{described_class}::PATIENTS_PER_DAY", 1)
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      patient2 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      expect {
        described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to change { Experimentation::TreatmentGroupMembership.count }.by(1)
    end

    it "limits participants to patients_per_day if provided" do
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      patient2 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      expect {
        described_class.schedule_daily_stale_patient_notifications(name: experiment.name, patients_per_day: 1)
      }.to change { Experimentation::TreatmentGroupMembership.count }.by(1)
    end

    it "does not create notifications or update experiment status if today is before the experiment before date" do
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients", start_date: 1.day.from_now, end_date: 1.week.from_now)
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)

      expect {
        described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to not_change { Experimentation::TreatmentGroupMembership.count }
        .and not_change { experiment.reload.state }
    end

    it "changes the experiment state to 'complete' and does not create notifications if today is after the experiment end date" do
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients", start_date: 1.week.ago, end_date: 1.day.ago)
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)

      expect {
        described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to change { experiment.reload.state }.from("new").to("complete")
        .and not_change { Experimentation::TreatmentGroupMembership.count }
    end
  end

  describe "self.abort_experiment" do
    it "raises error if experiment is not found" do
      expect {
        described_class.abort_experiment("fake")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "changes experiment state to 'cancelled' and changes pending and scheduled notification statuses to 'cancelled'" do
      experiment = create(:experiment, state: "new")
      patient = create(:patient)

      pending_notification = create(:notification, experiment: experiment, patient: patient, status: "pending")
      scheduled_notification = create(:notification, experiment: experiment, patient: patient, status: "scheduled")
      sent_notification = create(:notification, experiment: experiment, patient: patient, status: "sent")

      expect {
        described_class.abort_experiment(experiment.name)
      }.to change { experiment.reload.state }.to("cancelled")
      expect(pending_notification.reload.status).to eq("cancelled")
      expect(scheduled_notification.reload.status).to eq("cancelled")
      expect(sent_notification.reload.status).to eq("sent")
    end
  end

  # NOTE: putting a best attempt at an e2e test here for now, with the intention that we can
  # pull it out to its own dedicated integration test file soon
  describe "end to end testing" do
    before do
      Flipper.enable(:experiment)
    end

    it "successfully sends notifications to stale patients who have not had an appointment" do
      Sidekiq::Testing.inline! do
        twilio_double = double("TwilioApiService", send_sms: double("TwilioResponse", sid: "1234", status: :sent))
        expect(TwilioApiService).to receive(:new).and_return(twilio_double)

        patient = create(:patient, age: 80)
        create(:blood_pressure, patient: patient, device_created_at: 100.days.ago)
        experiment = Seed::ExperimentSeeder.create_stale_experiment(start_date: Date.current, end_date: 45.days.from_now)
        active_group = experiment.treatment_groups.find_by!(description: "single_notification")

        expect_any_instance_of(Experimentation::Experiment).to receive(:random_treatment_group).and_return(active_group)
        expect {
          described_class.schedule_daily_stale_patient_notifications(name: experiment.name)
        }.to change { experiment.notifications.count }.by(1)
          .and change { experiment.reload.state }.from("new").to("running")

        expect(active_group.patients.reload.include?(patient)).to be_truthy

        expect(Notification.count).to eq(1)
        notification = Notification.last
        notification.status_scheduled!
        AppointmentNotification::Worker.perform_async(notification.id)
      end
    end
  end
end
