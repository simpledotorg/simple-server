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
  Api::V4::PatientAttributeTransformer.to_response(patient_attribute).with_indifferent_access
end

def build_invalid_patient_attribute_payload
  build_patient_attribute_payload.merge(
    "created_at" => nil,
    "height" => "invalid"
  )
end

def updated_patient_attributes_payload(payload)
  update_time = 5.days.from_now
  build_patient_attribute_payload(payload).merge(
    "updated_at" => update_time
  )
end
