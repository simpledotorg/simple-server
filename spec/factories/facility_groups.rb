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

    transient do
      create_parent_region { Flipper.enabled?(:regions_prep) }
    end

    before(:create) do |fg, options|
      if options.create_parent_region
        create(:region,
          name: fg.state,
          region_type: :state,
          reparent_to: fg.organization.region)
      end
    end

    trait :without_parent_region do
      create_parent_region { false }
    end
  end
end
