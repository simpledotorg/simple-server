FactoryBot.define do
  factory :facility_group do
    transient do
      org { create(:organization) }
      state_name { Faker::Address.state }
    end

    id { SecureRandom.uuid }
    name { Faker::Address.district }
    description { Faker::Company.catch_phrase }
    organization { org }
    state { state_name }
    protocol

    transient do
      create_parent_region { Flipper.enabled?(:regions_prep) }
    end

    before(:create) { |fg, options|
      create(:region,
        name: fg.state,
        region_type: :state,
        reparent_to: fg.organization.region) if options.create_parent_region
    }

    trait :without_parent_region do
      create_parent_region { false }
    end
  end
end
