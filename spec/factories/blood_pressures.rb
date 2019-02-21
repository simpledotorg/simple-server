FactoryBot.define do
  factory :blood_pressure do
    id { SecureRandom.uuid }
    systolic { rand(80..240) }
    diastolic { rand(60..140) }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    deleted_at { [nil, Time.now].sample }
    association :facility, strategy: :build
    association :patient, strategy: :build
    user

    trait :critical do
      systolic { rand(180..240) }
      diastolic { rand(110..140) }
    end

    trait :very_high do
      systolic { rand(160..179) }
      diastolic { rand(100..109) }
    end

    trait :high do
      systolic { rand(140..159) }
      diastolic { rand(90..99) }
    end

    trait :under_control do
      systolic { rand(80..140) }
      diastolic { rand(60..90) }
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
