FactoryBot.define do
  factory :treatment_group, class: Experimentation::TreatmentGroup do
    sequence(:index) { |n| n - 1 }
    description { "emotional plea" }
    association :experiment, factory: :experiment
  end
end
