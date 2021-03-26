FactoryBot.define do
  factory :experiment, class: Experimentation::Experiment do
    name { Faker::Lorem.unique.word }
    state { "active" }
    start_date {}
    end_date {}
  end
end
