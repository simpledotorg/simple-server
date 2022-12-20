FactoryBot.define do
  factory :questionnaire do
    version_id { SecureRandom.uuid }
    questionnaire_type { "monthly_screening_reports" }
    dsl_version { 1 }
    association :questionnaire_version, strategy: :create
  end
end
