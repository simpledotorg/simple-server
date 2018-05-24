FactoryBot.define do
  factory :address do
    id { SecureRandom.uuid }
    street_address { Faker::Address.street_address }
    colony { Faker::Address.community }
    village { Faker::Address.community }
    district { Faker::Address.city }
    state { Faker::Address.state }
    country { Faker::Address.country }
    pin { Faker::Address.zip }
    created_at { Time.now }
    updated_at { Time.now }
    updated_on_server_at { Time.now }
  end
end