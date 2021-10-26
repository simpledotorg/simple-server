require "rails_helper"

RSpec.describe Seed::ExperimentSeeder do
  describe ".create_current_experiment" do
    it "creates experiment, treatment groups, and reminder templates" do
      expect(Experimentation::Experiment.count).to eq(0)
      expect(Experimentation::TreatmentGroup.count).to eq(0)
      expect(Experimentation::ReminderTemplate.count).to eq(0)

      experiment = described_class.create_current_experiment(start_time: 1.day.from_now, end_time: 2.days.from_now)

      expect(experiment).to be_current_patients
      expect(experiment.treatment_groups.count).to eq(3)
      cascade_templates = experiment.treatment_groups.find_by!(description: "cascade").reminder_templates
      expect(cascade_templates.count).to eq(3)
      single_notification_templates = experiment.treatment_groups.find_by!(description: "single_notification").reminder_templates
      expect(single_notification_templates.count).to eq(1)
    end
  end

  describe ".create_stale_experiment" do
    it "creates experiment, treatment groups, and reminder templates" do
      expect(Experimentation::Experiment.count).to eq(0)
      expect(Experimentation::TreatmentGroup.count).to eq(0)
      expect(Experimentation::ReminderTemplate.count).to eq(0)

      experiment = described_class.create_stale_experiment(start_time: 1.day.from_now, end_time: 2.days.from_now)

      expect(experiment).to be_stale_patients
      expect(experiment.treatment_groups.count).to eq(2)
      templates = experiment.treatment_groups.find_by!(description: "single_notification").reminder_templates
      expect(templates.count).to eq(1)
    end
  end
end
