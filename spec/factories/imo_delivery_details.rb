FactoryBot.define do
  factory :imo_delivery_detail do
    post_id { "imo_post_id" }
    result { :sent }
    callee_phone_number { Faker::PhoneNumber.phone_number }
    read_at {}
    association :communication
  end
end
