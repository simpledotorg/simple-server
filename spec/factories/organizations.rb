FactoryBot.define do
  factory :organization do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    parent_region { Region.root }
  end
end
