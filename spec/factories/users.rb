FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    security_pin_hash { Faker::Crypto.sha256 }
    association :facility, strategy: :build
  end
end
