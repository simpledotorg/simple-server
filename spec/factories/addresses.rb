FactoryBot.define do
  factory :address do
    id { SecureRandom.uuid }
    street_address { Faker::Address.street_address }
    village_or_colony { Faker::Address.community }
    district { Faker::Address.city }
    state { Faker::Address.state }
    country { Faker::Address.country }
    pin { Faker::Address.zip }
    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end