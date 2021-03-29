FactoryBot.define do
  factory :treatment_bucket, class: Experimentation::TreatmentBucket do
    sequence(:index) { |n| n - 1 }
    description { "emotional plea" }
    association :experiment, factory: :experiment
  end
end
