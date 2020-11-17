FactoryBot.define do
  factory :facility_group do
    transient do
      org { create(:organization) }
    end

    id { SecureRandom.uuid }
    name { Seed::FakeNames.instance.district }
    description { Faker::Company.catch_phrase }
    organization { org }
    state { Faker::Address.state }
    protocol
  end
end
