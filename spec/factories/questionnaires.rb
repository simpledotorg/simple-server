FactoryBot.define do
  factory :questionnaire do
    version_id { SecureRandom.uuid }
    questionnaire_type { "monthly_screening_reports" }
    dsl_version { 1 }
    questionnaire_version do
      association :questionnaire_version, strategy: :create, dsl_version: dsl_version
    end

  end
end
