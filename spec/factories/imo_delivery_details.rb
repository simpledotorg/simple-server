FactoryBot.define do
  factory :imo_delivery_detail do
    result { "sent" }
    callee_phone_number { Faker::PhoneNumber.phone_number }
    read_at {}
    association :communication
  end
end
