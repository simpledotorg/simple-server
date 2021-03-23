FactoryBot.define do
  factory :reminder_template, class: "Experiment::ReminderTemplate" do
    experiment_group { 0 }
    message { "Your appointment is in three days" }
    appointment_offset { -3 }
    association :reminder_experiment, factory: :reminder_experiment
  end
end
