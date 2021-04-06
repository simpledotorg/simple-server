module Seed
  class ExperimentSeeder
    include ActiveSupport::Benchmarkable

    def self.call
      new.call
    end

    def call
      experiment = Experimentation::Experiment.create!(name: "test-experiment", experiment_type: "current_patient_reminder",
                                                       state: "new", start_date: 2.days.from_now, end_date: 42.days.from_now)
      experiment.treatment_groups.create!(description: "control", index: 0)
      single = experiment.treatment_groups.create!(description: "single message", index: 1)
      single.reminder_templates.create!(message: "${patient_name}, please visit ${facility} on ${date} for a BP measure and medicines.",
                                        remind_on_in_days: -1)

      cascade = experiment.treatment_groups.create!(description: "cascaded message", index: 2)
      cascade.reminder_templates.create!(message: "${patient_name} please visit ${facility} on ${date} for a BP measure and medicines.",
                                         remind_on_in_days: -1)
      cascade.reminder_templates.create!(message: "${patient_name} you have an appointment today!",
                                         remind_on_in_days: 0)
    end
  end
end
