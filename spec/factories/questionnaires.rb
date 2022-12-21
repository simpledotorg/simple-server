FactoryBot.define do
  factory :questionnaire do
    version_id { SecureRandom.uuid }
    questionnaire_type { "monthly_screening_reports" }
    sequence :dsl_version
    association :questionnaire_version, strategy: :create
  end
end
