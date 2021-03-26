FactoryBot.define do
  factory :experiment, class: Experimentation::Experiment do
    name { Faker::Lorem.unique.word }
    state { "active" }
    subject_type { "scheduled_patients" }
    start_date {}
    end_date {}
  end
end
