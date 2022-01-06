# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    id { SecureRandom.uuid }
    street_address { Faker::Address.street_address }
    village_or_colony { Faker::Address.community }
    sequence(:zone) { |n| "Zone #{n}" }
    district { Faker::Address.city }
    state { Faker::Address.state }
    country { Faker::Address.country }
    pin { Faker::Address.zip }
    device_created_at { Time.current }
    device_updated_at { Time.current }

    trait(:no_street_address) do
      street_address { nil }
    end
  end
end
