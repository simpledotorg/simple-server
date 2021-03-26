FactoryBot.define do
  factory :treatment_cohort, class: Experimentation::TreatmentCohort do
    cohort_identifier { 0 }
    association :experiment, factory: :experiment
  end
end
