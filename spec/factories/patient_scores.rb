FactoryBot.define do
  factory :patient_score do
    id { SecureRandom.uuid }
    patient
    score_type { "risk_score" }
    score_value { 75.50 }
    device_created_at { Time.current }
    device_updated_at { Time.current }
  end
end
