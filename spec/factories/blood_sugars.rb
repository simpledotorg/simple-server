FactoryBot.define do
  factory :BloodSugar do
    id { SecureRandom.uuid }
    blood_sugar_type { 'random' }
    blood_sugar_value { 150 }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }
    facility
    user
    patient
  end
end

def build_blood_sugar_payload(blood_sugar = FactoryBot.build(:blood_sugar))
  Api::Current::Transformer.to_response(blood_sugar).with_indifferent_access
end

def build_invalid_blood_sugar_payload
  build_blood_sugar_payload.merge(
    'created_at' => nil,
    'blood_sugar_type' => 'invalid'
  )
end

def updated_blood_sugar_payload(existing_blood_sugar)
  update_time = 10.days.from_now
  build_blood_sugar_payload(existing_blood_sugar).merge(
    'updated_at' => update_time,
    'blood_sugar_value' => rand(80..240)
  )
end