FactoryBot.define do
  factory :region do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    region_type { "organization" }

    trait :block do
      region_type { :block }
    end

    trait :state do
      region_type { :state }
    end
  end
end

def setup_district_with_facilities
  facility_group = create(:facility_group, name: "Test District")
  {
    region: facility_group.region,
    block_1: create(:region, :block, name: "Test Block 1", reparent_to: facility_group.region),
    block_2: create(:region, :block, name: "Test Block 2", reparent_to: facility_group.region),
    facility_1: create(:facility, name: "Test Facility 1", facility_group: facility_group, facility_size: "community", zone: "Test Block 1"),
    facility_2: create(:facility, name: "Test Facility 2", facility_group: facility_group, facility_size: "small", zone: "Test Block 2")
  }
end
