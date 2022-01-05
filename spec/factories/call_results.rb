FactoryBot.define do
  factory :call_result do
    id { SecureRandom.uuid }
    association :user
    association :appointment
    remove_reason { nil }
    result_type { CallResult.result_types.except(:removed_from_overdue_list).keys.sample }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    deleted_at { nil }
  end
end

def build_call_result_payload(call_result = FactoryBot.build(:call_result, result_type: :agreed_to_visit))
  call_result.attributes.with_payload_keys
end

def build_invalid_call_result_payload
  build_call_result_payload.merge(
    "user_id" => nil,
    "result_type" => "foo"
  )
end

def updated_call_result_payload(existing_call_result)
  update_time = 10.days.from_now

  build_call_result_payload(existing_call_result).merge(
    "updated_at" => update_time,
    "remove_reason" => CallResult.remove_reasons.keys.sample
  )
end
