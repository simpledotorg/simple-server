FactoryBot.define do
  factory :facility_group do
    transient do
      org { create(:organization) }
      state_name { Faker::Address.state }
    end

    id { SecureRandom.uuid }
    name { Seed::FakeNames.instance.district }
    description { Faker::Company.catch_phrase }
    organization { org }
    state { state_name }
    protocol

    transient do
      create_parent_region { Flipper.enabled?(:regions_prep) }
    end

    before(:create) do |fg, options|
      if options.create_parent_region
        create(:region,
          :state,
          name: fg.state,
          reparent_to: fg.organization.region)
      end
    end

    trait :without_parent_region do
      create_parent_region { false }
    end
  end
end
