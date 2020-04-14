FactoryBot.define do
  factory :facility_group do
    transient do
      org { create(:organization) }
    end

    id { SecureRandom.uuid }
    name { Faker::Address.district }
    description { Faker::Company.catch_phrase }
    organization { org }
    protocol

    slug { name.parameterize.underscore }
  end
end
