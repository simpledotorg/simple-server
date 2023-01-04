FactoryBot.define do
  factory :questionnaire_version do
    id { SecureRandom.uuid }
    questionnaire_type { "monthly_screening_reports" }
    dsl_version { 1 }
    layout { {} }
  end
end
