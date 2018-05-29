FactoryBot.define do
  factory :blood_pressure do
    id { SecureRandom.uuid }
    systolic { rand(80..240) }
    diastolic { rand(60..140) }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    association :patient, strategy: :build
  end
end

def with_payload_keys(attributes)
  key_mapping = {
    'device_created_at' => 'created_at',
    'device_updated_at' => 'updated_at'
  }.with_indifferent_access

  attributes.transform_keys { |key| key_mapping[key] || key }
end

def build_blood_pressure_payload(blood_pressure = FactoryBot.build(:blood_pressure))
  with_payload_keys(blood_pressure.attributes)
end

def build_invalid_blood_pressure_payload
  build_blood_pressure_payload.merge(
    'created_at' => nil,
    'systolic'   => nil,
    'diastolic'  => 'foo'
  )
end

def updated_blood_pressure_payload(existing_blood_pressure)
  update_time = 10.days.from_now
  build_blood_pressure_payload(existing_blood_pressure).merge(
    'updated_at' => update_time,
    'systolic' => rand(80..240)
  )
end