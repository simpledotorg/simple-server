FactoryBot.define do
  factory :reminder_experiment, class: "Experiment::ReminderExperiment" do
    active { true }
    start_date {}
    end_date {}
  end
end
