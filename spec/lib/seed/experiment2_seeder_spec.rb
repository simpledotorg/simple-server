require "rails_helper"

RSpec.describe Seed::Experiment2Seeder do
  describe ".create_current_experiment" do
    it "creates experiment, treatment groups, and reminder templates" do
      described_class.create_current_experiment(
        start_time: 1.day.from_now,
        end_time: 2.days.from_now,
        experiment_name: "current patients",
        max_patients_per_day: 10
      )

      experiment = Experimentation::CurrentPatientExperiment.first

      expect(experiment).to be_current_patients
      expect(experiment.name).to eq("current patients")
      expect(experiment.max_patients_per_day).to eq(10)
      expect(experiment.treatment_groups.count).to eq(8)
      expect(experiment.reminder_templates.count).to eq(21)
      expect(experiment.reminder_templates.where(remind_on_in_days: -1).count).to eq(7)
      expect(experiment.reminder_templates.where(remind_on_in_days: 0).count).to eq(7)
      expect(experiment.reminder_templates.where(remind_on_in_days: 3).count).to eq(7)
    end
  end

  describe ".create_stale_experiment" do
    it "creates experiment, treatment groups, and reminder templates" do
      experiment = described_class.create_stale_experiment(
        start_time: 1.day.from_now,
        end_time: 2.days.from_now,
        experiment_name: "stale patients",
        max_patients_per_day: 10
      )

      expect(experiment).to be_stale_patients
      expect(experiment.name).to eq("stale patients")
      expect(experiment.max_patients_per_day).to eq(10)
      expect(experiment.treatment_groups.count).to eq(8)
      expect(experiment.reminder_templates.pluck(:message)).to match_array(%w[notifications.set03.basic
                                                                                     notifications.set03.gratitude
                                                                                     notifications.set03.free
                                                                                     notifications.set03.alarm
                                                                                     notifications.set03.emotional_relatives
                                                                                     notifications.set03.emotional_guilt
                                                                                     notifications.set03.professional_request])
      expect(experiment.reminder_templates.pluck(:remind_on_in_days)).to be_all 0
    end
  end
end
