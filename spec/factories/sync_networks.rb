FactoryBot.define do
  factory :sync_network do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    organisation
  end
end
