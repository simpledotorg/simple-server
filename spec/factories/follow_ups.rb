FactoryBot.define do
  factory :follow_up do
    id { SecureRandom.uuid }
    follow_up_schedule
    user
    follow_up_type { :call }
    follow_up_result { :answered }
    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_follow_up_payload(follow_up = FactoryBot.build(:follow_up))
  follow_up.attributes.with_payload_keys
end

def build_invalid_follow_up_payload
  build_follow_up_payload.merge(
    'follow_up_type' => nil,
    'follow_up_result' => 'foo'
  )
end

def updated_follow_up_payload(existing_follow_up)
  update_time = 10.days.from_now
  updated_result = FollowUp.follow_up_results.keys
                          .reject { |result| result == existing_follow_up.follow_up_result.to_s }
                          .sample

  build_follow_up_payload(existing_follow_up).merge(
    'updated_at' => update_time,
    'follow_up_result' => updated_result
  )
end