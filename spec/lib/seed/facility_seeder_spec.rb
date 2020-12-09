require "rails_helper"

[:enable, :disable].each do |toggle|
  RSpec.describe Seed::FacilitySeeder, "with regions_prep #{toggle}d" do
    before do
      Flipper.public_send(toggle, :regions_prep)
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
        .and change { Region.facility_regions.count }.by(8)
        .and change { FacilityGroup.count }.by(2)
        .and change { Facility.count }.by(8)
      expect(Region.block_regions.count).to be > 0
      expect(Region.state_regions.count).to be > 0
      # verify facility regions are linked up correctly
      Region.facility_regions.each do |region|
        expect(region.name).to eq(region.source.name)
        expect(region.district_region).to_not be_nil
        district = region.district_region
        block = region.block_region
        expect(district).to eq(region.source.facility_group.region)
        expect(block.parent).to eq(district)
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
  end
end
