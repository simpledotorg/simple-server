FactoryBot.define do
  factory :diabetes_observation do
    id { SecureRandom.uuid }
    observation_type { 'random' }
    obervation_value { 150 }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }
    facility
    user
    patient
  end
end

def build_diabetes_observation_payload(diabetes_observation = FactoryBot.build(:diabetes_observation))
  Api::Current::Transformer.to_response(diabetes_observation).with_indifferent_access
end

def build_invalid_diabetes_observation_payload
  build_diabetes_observation_payload.merge(
    'created_at' => nil,
    'observation_type' => 'invalid'
  )
end

def updated_diabetes_observation_payload(existing_diabetes_observation)
  update_time = 10.days.from_now
  build_diabetes_observation_payload(existing_diabetes_observation).merge(
    'updated_at' => update_time,
    'observation_value' => rand(80..240)
  )
end