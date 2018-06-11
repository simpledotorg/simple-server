FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    security_pin_hash { Faker::Crypto.sha256 }
    association :facility, strategy: :build
    device_created_at { Time.now }
    device_updated_at { Time.now }

    trait :created_on_device do
      id { SecureRandom.uuid }
      facility
    end

    factory :user_created_on_device, traits: [:created_on_device]
  end
end

def build_user_payload(user = FactoryBot.build(:user_created_on_device))
  user.attributes.with_payload_keys
end

def build_invalid_user_payload
  build_user_payload.merge(
    'created_at' => nil,
    'full_name' => nil
  )
end

def updated_user_payload(existing_user)
  update_time = 10.days.from_now
  build_user_payload(existing_user).merge(
    'updated_at' => update_time,
    'full_name' => Faker::Name.name
  )
end
