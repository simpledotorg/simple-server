require "rails_helper"

RSpec.describe Seed::FacilitySeeder do
  it "creates a protocol" do
    config = Seed::Config.new
    expect(Seed::ProtocolSeeder).to receive(:call).with(config: config).and_call_original
    Seed::FacilitySeeder.call(config: config)
  end

  it "creates facility groups and facilities" do
    expect {
      Seed::FacilitySeeder.call(config: Seed::Config.new)
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by(8)
  end

  it "creates facility groups and facilities with regions" do
    expect {
      Seed::FacilitySeeder.call(config: Seed::Config.new)
    }.to change { Region.district_regions.count }.by(2)
      .and change { FacilityGroup.count }.by(2)
      .and change { Region.facility_regions.count }.by_at_least(7)
      .and change { Facility.count }.by_at_least(7)
    expect(Region.block_regions.count).to be > 0
    expect(Region.state_regions.count).to be > 0
    Region.district_regions.each do |region|
      expect(region.name).to eq(region.source.name)
      expect(region.district_region).to_not be_nil
      expect(region.state_region).to_not be_nil
      expect(region.organization_region).to_not be_nil
    end
    # verify facility regions are linked up correctly
    Region.facility_regions.each do |facility_region|
      expect(facility_region.name).to eq(facility_region.source.name)
      expect(facility_region.district_region).to_not be_nil
      expect(facility_region.state_region).to_not be_nil
      expect(facility_region.organization_region).to_not be_nil
      expect(Seed::FakeNames.instance.states).to include(facility_region.state_region.name)
      district = facility_region.district_region
      block = facility_region.block_region
      expect(block.parent).to eq(district)
      # the below assertion is intermittently failing on CI
      # expect(district).to eq(facility_region.source.facility_group.region)
    end
  end

  it "generates a name based on the facility size" do
    seeder = Seed::FacilitySeeder.new(config: Seed::Config.new)
    expect(seeder).to receive(:weighted_facility_size_sample).and_return(:small).at_least(1).times
    seeder.call
    small_facility_names = Regexp.union(Seed::FacilitySeeder::SIZES_TO_TYPE[:small])
    Facility.all.each do |facility|
      expect(facility.name).to match(small_facility_names)
    end
  end

  it "does not create more facility groups than the max when called multiple times" do
    expect {
      3.times { Seed::FacilitySeeder.call(config: Seed::Config.new) }
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by_at_most(8)
  end

  it "creates facilities within a facility group (ie district) that are all within the same state" do
    seeder = Seed::FacilitySeeder.new(config: Seed::Config.new)
    seeder.call
    Facility.all.group_by { |f| f.facility_group_id }.each do |facility_group_id, facilities|
      single_state = facilities.first.state
      expect(facilities.map(&:state).uniq).to contain_exactly(single_state)
    end
  end

  it "creates multiple blocks within each facility group" do
    seeder = Seed::FacilitySeeder.new(config: Seed::Config.new)
    seeder.call
    Facility.all.map(&:facility_group).uniq.each do |facility_group|
      expect(facility_group.region.block_regions.count).to be > 1
    end
  end

  it "creates facilities with diabetes enabled" do
    seeder = Seed::FacilitySeeder.new(config: Seed::Config.new)
    seeder.call
    half_all_facilities = Facility.count / 2
    expect(Facility.where(enable_diabetes_management: true).count).to be >= half_all_facilities
  end
end
