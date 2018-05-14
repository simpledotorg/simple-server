FactoryBot.define do
  factory :phone_number do
    id { SecureRandom.uuid }
    number { Faker::PhoneNumber.phone_number }
    phone_type { PhoneNumber::PHONE_TYPE.sample }
    active { [true, false].sample }
    created_at { Time.now }
    updated_at { Time.now }
  end
end
