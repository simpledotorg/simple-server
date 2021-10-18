require "rails_helper"

RSpec.describe Experimentation::MedicationReminderService, type: :model do
  describe "self.schedule_daily_notifications" do
    let(:experiment) { create(:experiment, :upcoming, :with_treatment_group_and_template, experiment_type: "medication_reminder") }

    before :each do
      Flipper.enable(:experiment)
      experiment
    end

    it "does nothing if the feature flag is not enabled" do
      Flipper.disable(:experiment)

      patient1 = create(:patient)
      create(:blood_pressure, patient: patient1, device_created_at: 31.days.ago)

      Experimentation::MedicationReminderService.schedule_daily_notifications
      expect(Notification.count).to eq(0)
    end

    it "excludes patients who have had blood pressure readings in the past 30 days" do
      patient1 = create(:patient)
      create(:blood_pressure, patient: patient1, device_created_at: 31.days.ago)
      patient2 = create(:patient)
      create(:blood_pressure, patient: patient2, device_created_at: 30.days.ago)
      patient3 = create(:patient)
      create(:blood_pressure, patient: patient3, device_created_at: 29.days.ago)

      Experimentation::MedicationReminderService.schedule_daily_notifications

      expect(experiment.patients.include?(patient1)).to be_truthy
      expect(experiment.patients.include?(patient2)).to be_falsey
      expect(experiment.patients.include?(patient3)).to be_falsey
    end

    it "adds patients to treatment groups" do
      patient1 = create(:patient)
      create(:blood_pressure, patient: patient1, device_created_at: 31.days.ago)

      Experimentation::MedicationReminderService.schedule_daily_notifications

      treatment_group = experiment.treatment_groups.first
      expect(treatment_group.patients.include?(patient1)).to be_truthy
    end

    it "schedules notifications" do
      patient1 = create(:patient)
      create(:blood_pressure, patient: patient1, device_created_at: 31.days.ago)

      expect {
        Experimentation::MedicationReminderService.schedule_daily_notifications
      }.to change { patient1.notifications.count }.by(1)
    end

    it "schedules configured number of patients for each day of the experiment" do
      patient1 = create(:patient)
      create(:blood_pressure, patient: patient1, device_created_at: 31.days.ago)
      patient2 = create(:patient)
      create(:blood_pressure, patient: patient2, device_created_at: 31.days.ago)

      expect {
        Experimentation::MedicationReminderService.schedule_daily_notifications(patients_per_day: 1)
      }.to change { Notification.count }.by(1)
    end

    it "excludes anyone who's already in this experiment" do
      patient1 = create(:patient)
      create(:blood_pressure, patient: patient1, device_created_at: 31.days.ago)
      treatment_group = experiment.treatment_groups.first
      treatment_group.patients << patient1

      expect {
        Experimentation::MedicationReminderService.schedule_daily_notifications
      }.not_to change { Notification.count }
    end

    it "includes patients who are in other experiments" do
      experiment2 = create(:experiment, :with_treatment_group, start_time: 1.week.ago, end_time: 1.week.from_now)
      patient1 = create(:patient)
      create(:blood_pressure, patient: patient1, device_created_at: 31.days.ago)
      treatment_group = experiment2.treatment_groups.first
      treatment_group.patients << patient1

      Experimentation::MedicationReminderService.schedule_daily_notifications
      expect(treatment_group.patients.include?(patient1)).to be_truthy
    end
  end
end
