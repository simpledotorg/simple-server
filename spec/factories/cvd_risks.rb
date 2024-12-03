FactoryBot.define do
  factory :cvd_risk do
    id { SecureRandom.uuid }
    patient
    risk_score { 42 }
    device_created_at { Time.current }
    device_updated_at { Time.current }

    trait :invalid do
      risk_score { "not set" }
    end
  end
end

def updated_cvd_risk_payload existing_record = nil
  existing_record ||= build(:cvd_risk)
  existing_record.
    attributes.
    with_payload_keys.
    merge(updated_at: 5.days.from_now)
end
