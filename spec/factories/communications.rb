FactoryBot.define do
  factory :communication do
    id { SecureRandom.uuid }
    appointment
    user
    communication_type { :manual_call }
    communication_result { :successful }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    recorded_at { device_created_at }
  end
end

def build_communication_payload(communication = FactoryBot.build(:communication))
  communication.attributes.with_payload_keys
end

def build_invalid_communication_payload
  build_communication_payload.merge(
    'communication_type' => nil,
    'communication_result' => 'foo'
  )
end

def updated_communication_payload(existing_communication)
  update_time = 10.days.from_now
  updated_result = Communication.communication_results.keys
                          .reject { |result| result == existing_communication.communication_result.to_s }
                          .sample

  build_communication_payload(existing_communication).merge(
    'updated_at' => update_time,
    'communication_result' => updated_result
  )
end