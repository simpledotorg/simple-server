FactoryBot.define do
  factory :treatment_bucket, class: Experimentation::TreatmentBucket do
    index { 0 }
    description { "emotional plea" }
    association :experiment, factory: :experiment
  end
end
