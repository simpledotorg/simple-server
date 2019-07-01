FactoryBot.define do
  factory :call_log do
    id { rand(1..1000) }
    session_id { SecureRandom.uuid }
    result { CallLog.results.keys.sample }
    created_at { Time.now }
    updated_at { Time.now }
    duration { 60 }
    start_time { 1.minute.ago }
    end_time { Time.now }
    callee_phone_number { Faker::PhoneNumber }
    caller_phone_number { Faker::PhoneNumber }
  end
end