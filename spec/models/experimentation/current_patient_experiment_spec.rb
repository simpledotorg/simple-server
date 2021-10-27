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

      _earliest_reminder = create(:reminder_template, treatment_group: group, remind_on_in_days: -1)
      create(:reminder_template, treatment_group: group, remind_on_in_days: 0)

      expect(described_class.first.eligible_patients(scheduled_appointment_date - 3.days)).not_to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date - 2.days)).not_to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date + _earliest_reminder.remind_on_in_days.days)).to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date)).not_to include(patient)
      expect(described_class.first.eligible_patients(scheduled_appointment_date + 1.days)).not_to include(patient)
    end
  end
end
