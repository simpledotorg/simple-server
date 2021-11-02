require "rails_helper"

RSpec.describe Experimentation::CurrentPatientExperiment do
  describe "#eligible_patients" do
    it "calls super to get default eligible patients" do
      create(:experiment, experiment_type: "current_patients")
      allow(Experimentation::NotificationsExperiment).to receive(:eligible_patients).and_call_original
      expect(Experimentation::NotificationsExperiment).to receive(:eligible_patients)

      described_class.first.eligible_patients(Date.today)
    end

    it "includes patients who have an appointment on the date the first reminder is to be sent" do
      patient = create(:patient, age: 18)
      scheduled_appointment_date = 2.days.from_now
      create(:appointment, scheduled_date: scheduled_appointment_date, status: :scheduled, patient: patient)
      experiment = create(:experiment, experiment_type: "current_patients")
      group = create(:treatment_group, experiment: experiment)

      earliest_reminder = create(:reminder_template, message: "1", treatment_group: group, remind_on_in_days: -1)
      create(:reminder_template, message: "2", treatment_group: group, remind_on_in_days: 0)

      expect(described_class.first.eligible_patients(scheduled_appointment_date - 3.days)).not_to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date - 2.days)).not_to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date + earliest_reminder.remind_on_in_days.days)).to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date)).not_to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date + 1.days)).not_to include(patient)
    end
  end

  describe "#memberships_to_notify" do
    it "returns treatment_group_memberships whose expected visit is in the future and need to be reminded `remind_on_in_days` before" do
      experiment = create(:experiment, experiment_type: "current_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      patient_1 = create(:patient)
      patient_2 = create(:patient)

      membership_1 = treatment_group.enroll(patient_1, expected_return_date: 2.days.from_now.to_date)
      membership_2 = treatment_group.enroll(patient_2, expected_return_date: 3.days.from_now.to_date)

      create(:reminder_template, message: "1", treatment_group: treatment_group, remind_on_in_days: -2)
      create(:reminder_template, message: "2", treatment_group: treatment_group, remind_on_in_days: -3)
      create(:reminder_template, message: "3", treatment_group: treatment_group, remind_on_in_days: 0)

      expect(described_class.first.memberships_to_notify(Date.today)).to contain_exactly(membership_1, membership_2)
      expect(described_class.first.memberships_to_notify(Date.today).select(:message).pluck(:message)).to contain_exactly("1", "2")
    end

    it "returns treatment_group_memberships whose expected visit is today and need to be reminded `remind_on_in_days` today" do
      experiment = create(:experiment, experiment_type: "current_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient)
      membership = treatment_group.enroll(patient, expected_return_date: Date.today)
      create(:reminder_template, treatment_group: treatment_group, remind_on_in_days: 0)

      expect(described_class.first.memberships_to_notify(Date.today)).to contain_exactly(membership)
    end

    it "returns treatment_group_memberships whose expected visit date has passed by `remind_on_in_days` days away" do
      experiment = create(:experiment, experiment_type: "current_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      patient_1 = create(:patient)
      patient_2 = create(:patient)

      membership_1 = treatment_group.enroll(patient_1, expected_return_date: 1.days.from_now.to_date)
      membership_2 = treatment_group.enroll(patient_2, expected_return_date: 10.days.from_now.to_date)

      create(:reminder_template, message: "1", treatment_group: treatment_group, remind_on_in_days: -1)
      create(:reminder_template, message: "2", treatment_group: treatment_group, remind_on_in_days: -10)
      create(:reminder_template, message: "3", treatment_group: treatment_group, remind_on_in_days: 1)

      expect(described_class.first.memberships_to_notify(Date.today)).to contain_exactly(membership_1, membership_2)
      expect(described_class.first.memberships_to_notify(Date.today).select(:message).pluck(:message)).to contain_exactly("1", "2")
    end

    it "only picks patients who are still enrolled in the experiment" do
      experiment = create(:experiment, experiment_type: "current_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      patient_1 = create(:patient)
      patient_2 = create(:patient)

      membership_1 = treatment_group.enroll(patient_1, expected_return_date: Date.today, status: :enrolled)
      _membership_2 = treatment_group.enroll(patient_2, expected_return_date: Date.today, status: :evicted)
      create(:reminder_template, treatment_group: treatment_group, remind_on_in_days: 0)

      expect(described_class.first.memberships_to_notify(Date.today)).to contain_exactly(membership_1)
    end
  end
end
