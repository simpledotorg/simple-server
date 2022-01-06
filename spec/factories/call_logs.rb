# frozen_string_literal: true

FactoryBot.define do
  factory :call_log do
    id { Faker::Number.unique.number }
    session_id { SecureRandom.uuid }
    result { CallLog.results.keys.sample }
    created_at { Time.current }
    updated_at { Time.current }
    duration { 60 }
    start_time { 1.minute.ago }
    end_time { Time.current }
    callee_phone_number { Faker::PhoneNumber }
    caller_phone_number { Faker::PhoneNumber }
  end
end
