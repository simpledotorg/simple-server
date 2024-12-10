FactoryBot.define do
  factory :cvd_risk do
    id { SecureRandom.uuid }
    patient
    risk_score { "42" }
    device_created_at { Time.current }
    device_updated_at { Time.current }

    trait :invalid do
      risk_score { "not set" }
    end
  end
end
