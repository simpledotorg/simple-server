FactoryBot.define do
  factory :facility_group do
    transient do
      org { create(:organization) }
    end

    id { SecureRandom.uuid }
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    organization { org }
    protocol
  end
end
