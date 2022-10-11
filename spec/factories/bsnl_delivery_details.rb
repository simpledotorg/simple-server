FactoryBot.define do
  factory :bsnl_delivery_detail do
    sequence(:message_id) { |n| "#{n}000000" }
    message_status { "0" }
    recipient_number { Faker::PhoneNumber.phone_number }
    dlt_template_id { "14071640000000000000" }
    result { "Message Created" }
    delivered_on { nil }

    association :communication

    trait(:created) { message_status { "0" } }
  end
end
