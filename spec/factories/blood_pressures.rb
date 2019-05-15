FactoryBot.define do
  factory :blood_pressure do
    id { SecureRandom.uuid }
    systolic { rand(80..240) }
    diastolic { rand(60..140) }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    recorded_at { device_created_at }
    deleted_at { [nil, Time.now].sample }
    association :facility, strategy: :build
    association :patient, strategy: :build
    user

    trait :critical do
      systolic 181
      diastolic 111
    end

    trait :very_high do
      systolic 160
      diastolic 100
    end

    trait :high do
      systolic 140
      diastolic 90
    end

    trait :under_control do
      systolic 80
      diastolic 60
    end
  end
end

def build_blood_pressure_payload(blood_pressure = FactoryBot.build(:blood_pressure))
  blood_pressure.attributes.with_payload_keys
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
