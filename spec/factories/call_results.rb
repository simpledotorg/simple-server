FactoryBot.define do
  factory :call_result do
    id { SecureRandom.uuid }
    association :user
    association :appointment
    cancel_reason { nil }
    result { CallResult.results.keys.sample }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    deleted_at { nil }
  end
end

def build_call_result_payload(call_result = FactoryBot.build(:call_result))
  call_result.attributes.with_payload_keys
end

def build_invalid_call_result_payload
  build_call_result_payload.merge(
    "user" => nil,
    "result" => "foo"
  )
end
