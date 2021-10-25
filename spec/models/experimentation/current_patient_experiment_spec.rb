require "rails_helper"

RSpec.describe Experimentation::CurrentPatientExperiment do
  describe "#eligible_patients" do
    it "includes patients who have an appointment on the date the first reminder is to be sent" do
      patient = create(:patient, age: 18)
      create(:appointment, scheduled_date: 2.days.from_now, status: :scheduled, patient: patient)
      experiment = create(:experiment, experiment_type: "current_patients")
      group = create(:treatment_group, experiment: experiment)
      create(:reminder_template, treatment_group: group, remind_on_in_days: -1)
      create(:reminder_template, treatment_group: group, remind_on_in_days: 0)

      expect(described_class.first.eligible_patients(Date.yesterday)).not_to include(patient)
      expect(described_class.first.eligible_patients(Date.current)).not_to include(patient)
      expect(described_class.first.eligible_patients(Date.tomorrow)).to include(patient)
      expect(described_class.first.eligible_patients(Date.current + 2.days)).not_to include(patient)
    end
  end
end
