FactoryBot.define do
  factory :alpha_sms_delivery_detail do
    request_id { "1950547" }
    request_status { "Complete" }
    recipient_number { Faker::PhoneNumber.phone_number }
    message { "Test message" }

    association :communication
  end
end
