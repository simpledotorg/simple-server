# frozen_string_literal: true

FactoryBot.define do
  factory :facility_group do
    transient do
      state_name { Faker::Address.state }
    end

    id { SecureRandom.uuid }
    name { Seed::FakeNames.instance.district }
    description { Faker::Company.catch_phrase }
    organization { common_org }
    state { state_name }
    protocol { build(:protocol, :with_minimal_drugs) }

    transient do
      create_parent_region { true }
    end

    before(:create) do |facility_group, options|
      if options.create_parent_region
        facility_group.organization.region.state_regions.find_by(name: facility_group.state) ||
          create(:region, :state, name: facility_group.state, reparent_to: facility_group.organization.region)
      end
    end

    trait :without_parent_region do
      create_parent_region { false }
    end
  end
end
