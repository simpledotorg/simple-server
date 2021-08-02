require "rails_helper"

describe ExperimentControlService, type: :model do
  include ActiveJob::TestHelper

  describe "self.start_current_patient_experiment" do
    it "only selects from patients 18 and older" do
      young_patient = create(:patient, age: 17)
      old_patient = create(:patient, age: 18)
      create(:appointment, patient: young_patient, scheduled_date: 10.days.from_now)
      create(:appointment, patient: old_patient, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

      expect(experiment.patients.include?(old_patient)).to be_truthy
      expect(experiment.patients.include?(young_patient)).to be_falsey
    end

    it "only selects hypertensive patients" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      patient2 = create(:patient, :without_hypertension, age: 80)
      create(:appointment, patient: patient2, scheduled_date: 10.days.from_now)

      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

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

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

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

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: days_til_start, days_til_end: days_til_end)

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

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

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

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35, percentage_of_patients: percentage)

      expect(experiment.patients.count).to eq(1)
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:appointment, patient: patient, scheduled_date: 10.days.from_now)
      experiment = create(:experiment, :with_treatment_group)

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

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

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

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

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

      reminder1, reminder2, reminder3 = patient1.notifications.sort_by { |ar| ar.remind_on }
      expect(reminder1.remind_on).to eq(appointment_date - 3.days)
      expect(reminder2.remind_on).to eq(appointment_date)
      expect(reminder3.remind_on).to eq(appointment_date + 3.days)
    end

    it "only creates a notification for scheduled appointments during the window" do
      patient1 = create(:patient, age: 80)
      scheduled_appointment = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now, status: "scheduled")
      visited_appointment = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now, status: "visited")
      experiment = create(:experiment, :with_treatment_group)
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)

      expect(scheduled_appointment.notifications.count).to eq 1
      expect(visited_appointment.notifications.count).to eq 0
    end

    it "creates experimental reminder notifications with correct attributes" do
      patient1 = create(:patient, age: 80)
      appointment = create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      experiment = create(:experiment, :with_treatment_group)
      template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect {
        ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)
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

    it "updates the experiment state, start date, and end date" do
      days_til_start = 5
      days_til_end = 35
      experiment = create(:experiment)
      ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: days_til_start, days_til_end: days_til_end)
      experiment.reload

      expect(experiment).to be_running_state
      expect(experiment.start_date).to eq(days_til_start.days.from_now.to_date)
      expect(experiment.end_date).to eq(days_til_end.days.from_now.to_date)
    end

    it "does not create appointment reminders or update the experiment if there's another experiment of the same type in progress" do
      experiment = create(:experiment)
      create(:experiment, state: "selecting")
      expect {
        ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Notification.count).to eq(0)
      expect(experiment.reload.state).to eq("new")
    end

    it "raises an error if the days_til_end is less than days_til_start" do
      experiment = create(:experiment)

      expect {
        ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 35, days_til_end: 5)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "does nothing if the experiment is not in 'new' state" do
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, scheduled_date: 10.days.from_now)
      experiment = create(:experiment, :with_treatment_group, state: "running")
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect {
        ExperimentControlService.start_current_patient_experiment(name: experiment.name, days_til_start: 5, days_til_end: 35)
      }.not_to change { experiment.reload.state }
      expect(Notification.count).to eq(0)
    end

    it "does nothing if the experiment is not found" do
      expect {
        ExperimentControlService.start_current_patient_experiment(name: "doesn't exist", days_til_start: 5, days_til_end: 35)
      }.not_to raise_error
      expect(Notification.count).to eq(0)
    end
  end

  describe "self.schedule_daily_stale_patient_notifications" do
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

      ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)

      expect(experiment.patients.include?(patient1)).to be_falsey
      expect(experiment.patients.include?(patient2)).to be_truthy
      expect(experiment.patients.include?(patient3)).to be_truthy
    end

    it "adds patients to treatment groups" do
      patient = create(:patient, age: 80)
      create(:blood_pressure, patient: patient, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)

      expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
    end

    it "creates experimental reminder notifications with correct attributes for selected patients" do
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      appointment = create(:appointment, patient: patient1, scheduled_date: 70.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to change { patient1.notifications.count }.by(1)
      notification = patient1.notifications.last
      expect(notification.remind_on).to eq(Date.current)
      expect(notification.purpose).to eq("experimental_appointment_reminder")
      expect(notification.message).to eq(template.message)
      expect(notification.status).to eq("pending")
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

      ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)

      today = Date.current
      reminder1, reminder2 = patient1.notifications.sort_by { |ar| ar.remind_on }
      expect(reminder1.remind_on).to eq(today)
      expect(reminder2.remind_on).to eq(today + 3.days)
    end

    it "updates the experiment state" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)
      experiment.reload

      expect(experiment).to be_running_state
    end

    it "does not create appointment reminders or update the experiment if there's another experiment of the same type in progress" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      create(:experiment, experiment_type: "stale_patients", state: "selecting")
      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Notification.count).to eq(0)
      expect(experiment.reload.state).to eq("new")
    end

    it "does nothing if it the experiment is not in 'new' or 'running' state" do
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients", state: "complete")
      group = experiment.treatment_groups.first
      create(:reminder_template, treatment_group: group, message: "come today", remind_on_in_days: 0)
      patient1 = create(:patient, age: 80)
      create(:appointment, patient: patient1, device_created_at: 100.days.ago, scheduled_date: 100.days.ago)

      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.not_to change { experiment.reload }
      expect(Notification.count).to eq(0)
    end

    it "does nothing if the experiment is not found" do
      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: "doesn't exist")
      }.not_to raise_error
      expect(Notification.count).to eq(0)
    end

    it "only schedules reminders for PATIENTS_PER_DAY by default" do
      stub_const("ExperimentControlService::PATIENTS_PER_DAY", 1)
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      patient2 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to change { Experimentation::TreatmentGroupMembership.count }.by(1)
    end

    it "limits participants to patients_per_day if provided" do
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)
      patient2 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient2, device_created_at: 100.days.ago)
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")

      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name, patients_per_day: 1)
      }.to change { Experimentation::TreatmentGroupMembership.count }.by(1)
    end

    it "does not create notifications or update experiment status if today is before the experiment before date" do
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients", start_date: 1.day.from_now, end_date: 1.week.from_now)
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)

      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.not_to change { Experimentation::TreatmentGroupMembership.count }
      expect(experiment.reload.state).to eq("new")
    end

    it "changes the experiment state to 'complete' and does not create notifications if today is after the experiment end date" do
      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients", start_date: 1.week.ago, end_date: 1.day.ago)
      patient1 = create(:patient, age: 80)
      create(:blood_pressure, patient: patient1, device_created_at: 100.days.ago)

      expect {
        ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)
      }.to change { experiment.reload.state }.from("new").to("complete")
      expect(Experimentation::TreatmentGroupMembership.count).to eq(0)
    end
  end

  describe "self.abort_experiment" do
    it "raises error if experiment is not found" do
      expect {
        ExperimentControlService.abort_experiment("fake")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "changes experiment state to 'cancelled' and changes pending and scheduled notification statuses to 'cancelled'" do
      experiment = create(:experiment, state: "new")
      patient = create(:patient)

      pending_notification = create(:notification, experiment: experiment, patient: patient, status: "pending")
      scheduled_notification = create(:notification, experiment: experiment, patient: patient, status: "scheduled")
      sent_notification = create(:notification, experiment: experiment, patient: patient, status: "sent")

      expect {
        ExperimentControlService.abort_experiment(experiment.name)
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
      Sidekiq::Testing.inline!
      twilio_double = double("TwilioApiService", send_sms: true)
      expect(TwilioApiService).to receive(:new).and_return(twilio_double)

      patient = create(:patient, age: 80)
      create(:blood_pressure, patient: patient, device_created_at: 100.days.ago)
      experiment = Seed::ExperimentSeeder.create_stale_experiment(start_date: Date.current, end_date: 45.days.from_now)
      _template = create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      ExperimentControlService.schedule_daily_stale_patient_notifications(name: experiment.name)

      perform_enqueued_jobs do
        expect(experiment.treatment_groups.first.patients.include?(patient)).to be_truthy
        expect(Notification.count).to eq(1)
        notification = Notification.last
        notification.status_scheduled!
        AppointmentNotification::Worker.perform_async(notification.id)
      end
    end
  end
end
