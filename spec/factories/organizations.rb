# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
  end
end
