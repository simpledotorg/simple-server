FactoryBot.define do
  factory :patient_attribute do
    id { SecureRandom.uuid }
    patient
    height { 140.5 }
    weight { 65.5 }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    user

    trait :invalid do
      height { "invalid" }
      weight { "invalid" }
    end
  end
end

def build_patient_attribute_payload(patient_attribute = FactoryBot.build(:patient_attribute))
  patient_attribute.attributes.with_payload_keys
end

def build_invalid_patient_attribute_payload
  FactoryBot.build(:patient_attribute, :invalid)
end
