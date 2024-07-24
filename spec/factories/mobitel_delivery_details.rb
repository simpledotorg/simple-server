FactoryBot.define do
  factory :mobitel_delivery_detail do
    recipient_number { Faker::PhoneNumber.phone_number }
    message { "Test message" }

    association :communication
  end
end
