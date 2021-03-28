FactoryBot.define do
  factory :treatment_cohort, class: Experimentation::TreatmentCohort do
    bucketing_index { 0 }
    description { "emotional plea" }
    association :experiment, factory: :experiment
  end
end
