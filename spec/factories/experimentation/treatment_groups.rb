FactoryBot.define do
  factory :treatment_group, class: Experimentation::TreatmentGroup do
    description { Faker::Lorem.unique.word }
    association :experiment, factory: :experiment
  end
end
