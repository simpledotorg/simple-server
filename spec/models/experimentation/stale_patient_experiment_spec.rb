require "rails_helper"

RSpec.describe Experimentation::StalePatientExperiment do
  describe "#eligible_patients" do
    it "calls super to get default eligible patients" do
      create(:experiment, experiment_type: "stale_patients")
      allow(Experimentation::NotificationsExperiment).to receive(:eligible_patients).and_call_original
      expect(Experimentation::NotificationsExperiment).to receive(:eligible_patients)
      RefreshReportingViews.new.refresh_v2

      described_class.first.eligible_patients(Date.today)
    end

    it "only selects from patients 18 and older" do
      create(:experiment, experiment_type: "stale_patients")
      young_patient = create(:patient, age: 17)
      create(:bp_with_encounter, patient: young_patient, device_created_at: 100.days.ago)
      old_patient = create(:patient, age: 18)
      create(:bp_with_encounter, patient: old_patient, device_created_at: 100.days.ago)
      RefreshReportingViews.new.refresh_v2

      result = described_class.first.eligible_patients(Date.tomorrow)

      expect(result).to contain_exactly(old_patient)
    end

    it "only selects hypertensive patients" do
      create(:experiment, experiment_type: "stale_patients")
      hypertensive = create(:patient, age: 80)
      create(:bp_with_encounter, patient: hypertensive, device_created_at: 100.days.ago)
      non_hypertensive = create(:patient, :without_hypertension, age: 80)
      create(:bp_with_encounter, patient: non_hypertensive, device_created_at: 100.days.ago)
      RefreshReportingViews.new.refresh_v2

      result = described_class.first.eligible_patients(Date.tomorrow)

      expect(result).to contain_exactly(hypertensive)
    end

    it "only selects patients with mobile phones" do
      create(:experiment, experiment_type: "stale_patients")
      patient_without_phone = create(:patient, age: 80, phone_numbers: [])
      patient_with_landline = create(:patient, phone_numbers: [build(:patient_phone_number, phone_type: :landline)])
      create(:bp_with_encounter, patient: patient_without_phone, device_created_at: 100.days.ago)
      create(:bp_with_encounter, patient: patient_with_landline, device_created_at: 100.days.ago)

      patient_with_phone = create(:patient, age: 80)
      create(:bp_with_encounter, patient: patient_with_phone, device_created_at: 100.days.ago)
      RefreshReportingViews.new.refresh_v2

      result = described_class.first.eligible_patients(Date.tomorrow)

      expect(result).to contain_exactly(patient_with_phone)
    end

    it "only selects patients whose last visit was in the selected date range" do
      create(:experiment, experiment_type: "stale_patients")
      eligible_1 = create(:patient, age: 55)
      create(:prescription_drug, patient: eligible_1, device_created_at: 70.days.ago)
      eligible_2 = create(:patient, age: 80)
      create(:appointment, patient: eligible_2, device_created_at: 100.days.ago, scheduled_date: 80.days.ago)
      ineligible_1 = create(:patient, age: 80)
      create(:blood_sugar_with_encounter, patient: ineligible_1, device_created_at: 370.days.ago)
      ineligible_2 = create(:patient, age: 80)
      create(:bp_with_encounter, patient: ineligible_2, device_created_at: 1.days.ago)
      create(:blood_sugar_with_encounter, patient: ineligible_1, device_created_at: 10.days.ago)

      ineligible_3 = create(:patient, age: 80)
      create(:bp_with_encounter, patient: ineligible_3, device_created_at: 100.days.ago)
      create(:bp_with_encounter, patient: ineligible_3, device_created_at: 10.days.ago)

      RefreshReportingViews.new.refresh_v2

      result = described_class.first.eligible_patients(Date.tomorrow)

      expect(result).to contain_exactly(eligible_1, eligible_2)
    end

    it "only selects patients who have no appointments scheduled in the future" do
      create(:experiment, experiment_type: "stale_patients")
      patient_with_future_appt = create(:patient, age: 80)
      create(:bp_with_encounter, patient: patient_with_future_appt, device_created_at: 40.days.ago)
      patient_with_future_appt.appointments << create(:appointment, scheduled_date: Date.current + 1.day, status: "scheduled")

      patient_with_past_appt = create(:patient, age: 80)
      create(:bp_with_encounter, patient: patient_with_past_appt, device_created_at: 40.days.ago)
      create(:appointment, patient: patient_with_past_appt, device_created_at: 70.days.ago, scheduled_date: 40.days.ago)
      RefreshReportingViews.new.refresh_v2

      result = described_class.first.eligible_patients(Date.tomorrow)

      expect(result).to contain_exactly(patient_with_past_appt)
    end

    it "does not include any patients that have an appointment with remind_on in the future" do
      create(:experiment, experiment_type: "stale_patients")
      patient_with_past_remind_on = create(:patient, age: 80)
      patient_with_future_remind_on = create(:patient, age: 80)
      patient_without_future_remind_on = create(:patient, age: 80)

      create(:appointment,
        patient: patient_with_past_remind_on,
        device_created_at: 70.days.ago,
        scheduled_date: 40.days.ago,
        remind_on: 10.days.ago)
      create(:appointment,
        patient: patient_with_future_remind_on,
        device_created_at: 70.days.ago,
        scheduled_date: 40.days.ago,
        remind_on: 10.days.from_now)
      create(:appointment,
        patient: patient_without_future_remind_on,
        device_created_at: 70.days.ago,
        scheduled_date: 40.days.ago)
      RefreshReportingViews.new.refresh_v2

      result = described_class.first.eligible_patients(Date.tomorrow)

      expect(result).to contain_exactly(patient_with_past_remind_on, patient_without_future_remind_on)
    end

    it "does not include the same patient more than once" do
      create(:experiment, experiment_type: "stale_patients")
      patient = create(:patient, age: 80)
      create(:bp_with_encounter, patient: patient, device_created_at: 90.days.ago)
      create(:appointment, patient: patient, device_created_at: 120.days.ago, scheduled_date: 90.days.ago, status: "scheduled")
      RefreshReportingViews.new.refresh_v2

      result = described_class.first.eligible_patients(Date.tomorrow)

      expect(result).to contain_exactly(patient)
    end
  end

  describe "#memberships_to_notify" do
    it "returns treatment_group_memberships who were enrolled today and need to be reminded today" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient)
      membership = treatment_group.enroll(patient, experiment_inclusion_date: Date.today)
      create(:reminder_template, treatment_group: treatment_group, remind_on_in_days: 0)

      expect(described_class.first.memberships_to_notify(Date.today)).to contain_exactly(membership)
    end

    it "returns treatment_group_memberships whose were enrolled in the past `remind_on_in_days` days ago" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      patient_1 = create(:patient)
      patient_2 = create(:patient)

      membership_1 = treatment_group.enroll(patient_1, experiment_inclusion_date: 1.days.ago.to_date)
      membership_2 = treatment_group.enroll(patient_2, experiment_inclusion_date: 10.days.ago.to_date)

      create(:reminder_template, message: "1", treatment_group: treatment_group, remind_on_in_days: 1)
      create(:reminder_template, message: "2", treatment_group: treatment_group, remind_on_in_days: 10)
      create(:reminder_template, message: "3", treatment_group: treatment_group, remind_on_in_days: 0)

      expect(described_class.first.memberships_to_notify(Date.today)).to contain_exactly(membership_1, membership_2)
      expect(described_class.first.memberships_to_notify(Date.today).select(:message).pluck(:message)).to contain_exactly("1", "2")
    end

    it "only picks patients who are still enrolled in the experiment" do
      experiment = create(:experiment, experiment_type: "stale_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      patient_1 = create(:patient)
      patient_2 = create(:patient)

      membership_1 = treatment_group.enroll(patient_1, experiment_inclusion_date: Date.today, status: :enrolled)
      _membership_2 = treatment_group.enroll(patient_2, experiment_inclusion_date: Date.today, status: :evicted)
      create(:reminder_template, treatment_group: treatment_group, remind_on_in_days: 0)

      expect(described_class.first.memberships_to_notify(Date.today)).to contain_exactly(membership_1)
    end
  end
end
