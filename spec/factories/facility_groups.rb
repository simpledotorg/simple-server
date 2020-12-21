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
      create_parent_region { true }
    end

    before(:create) do |facility_group, options|
      if options.create_parent_region
        if facility_group.organization.region.nil?
          raise ArgumentError, <<-EOL.strip_heredoc
            The facility group's organization lacks a region, which is required for regions_prep.
            Check the ordering of fixtures, something was probably created before the regions_prep flag was enabled."
          EOL
        end

        facility_group.organization.region.state_regions.find_by(name: facility_group.state) ||
          create(:region, :state, name: facility_group.state, reparent_to: facility_group.organization.region)
      end
    end

    trait :without_parent_region do
      create_parent_region { false }
    end
  end
end
