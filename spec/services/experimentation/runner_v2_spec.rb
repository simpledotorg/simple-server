require "rails_helper"

describe Experimentation::RunnerV2, type: :model do
  describe ".call" do
    before { Flipper.enable(:experiment) }

    it "does not add patients, or create notifications if the feature flag is off" do
      Flipper.disable(:experiment)

      patient1 = create(:patient, age: 80)
      create(:blood_sugar, patient: patient1, device_created_at: 100.days.ago)

      experiment = create(:experiment, :with_treatment_group, experiment_type: "stale_patients")
      create(:reminder_template, treatment_group: experiment.treatment_groups.first, message: "come today", remind_on_in_days: 0)

      described_class.call

      expect(experiment.patients.count).to eq(0)
      expect(experiment.notifications.count).to eq(0)
    end

    it "calls conduct_daily on current and stale experiments with today's date" do
      expect(Experimentation::CurrentPatientExperiment).to receive(:conduct_daily).with(Date.current)
      expect(Experimentation::StalePatientExperiment).to receive(:conduct_daily).with(Date.current)

      described_class.call
    end
  end
end
