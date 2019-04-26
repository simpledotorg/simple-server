FactoryBot.define do
  factory :twilio_sms_delivery_detail do
    session_id { SecureRandom.uuid }
    result { 'sent' }
    callee_phone_number { Faker::PhoneNumber.phone_number }
    delivered_on nil
    association :communication
  end
end
