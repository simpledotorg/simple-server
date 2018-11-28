FactoryBot.define do
  factory :organisation do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
  end
end
