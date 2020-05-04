FactoryBot.define do
  factory :blood_pressure do
    id { SecureRandom.uuid }
    systolic { rand(80..240) }
    diastolic { rand(60..140) }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }

    association :facility, strategy: :create
    association :user, strategy: :create
    association :patient, strategy: :create

    trait :critical do
      systolic { 181 }
      diastolic { 111 }
    end

    trait :hypertensive do
      systolic { 140 }
      diastolic { 90 }
    end

    trait :under_control do
      systolic { 80 }
      diastolic { 60 }
    end
  end
end

def build_blood_pressure_payload(blood_pressure = FactoryBot.build(:blood_pressure))
  Api::V3::Transformer.to_response(blood_pressure).with_indifferent_access
end

def build_blood_pressure_payload_v2(blood_pressure = FactoryBot.build(:blood_pressure))
  Api::V2::BloodPressureTransformer.to_response(blood_pressure).with_indifferent_access
end

def build_invalid_blood_pressure_payload
  build_blood_pressure_payload.merge(
    'created_at' => nil,
    'systolic' => nil,
    'diastolic' => 'foo'
  )
end

def updated_blood_pressure_payload(existing_blood_pressure)
  update_time = 10.days.from_now
  build_blood_pressure_payload(existing_blood_pressure).merge(
    'updated_at' => update_time,
    'systolic' => rand(80..240)
  )
end

def updated_blood_pressure_payload_v2(existing_blood_pressure)
  updated_blood_pressure_payload(existing_blood_pressure)
    .except('recorded_at')
end
