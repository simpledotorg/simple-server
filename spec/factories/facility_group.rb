FactoryBot.define do
  factory :facility_group do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    organization
  end
end
