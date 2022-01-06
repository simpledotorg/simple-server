# frozen_string_literal: true

FactoryBot.define do
  factory :twilio_sms_delivery_detail do
    session_id { SecureRandom.uuid }
    result { "sent" }
    callee_phone_number { Faker::PhoneNumber.phone_number }
    delivered_on { nil }
    association :communication

    trait(:sent) { result { "sent" } }
    trait(:failed) { result { "failed" } }
    trait(:queued) { result { "queued" } }
    trait(:delivered) { result { "delivered" } }
    trait(:undelivered) { result { "undelivered" } }
  end
end
