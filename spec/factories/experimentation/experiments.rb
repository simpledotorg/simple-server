FactoryBot.define do
  factory :experiment, class: Experimentation::Experiment do
    lookup_name { Faker::Lorem.unique.word }
    state { "new" }
    experiment_type { "current_patient_reminder" }
    start_date {}
    end_date {}
  end
end
