FactoryBot.define do
  factory :treatment_group, class: Experimentation::TreatmentGroup do
    index { 0 }
    description { Faker::Lorem.unique.word }
    association :experiment, factory: :experiment
  end
end
