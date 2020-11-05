require "rails_helper"

RSpec.describe RegionBackfill, type: :model do
  context "dry run mode" do
    before do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      _facility_group_2 = create(:facility_group, organization: org)
      create(:facility, facility_group: facility_group_1)
    end

    it "does not create any records" do
      expect {
        RegionBackfill.call(dry_run: true)
      }.to_not change { Region.count }
    end
  end

  context "write mode" do
    it "fails in countries other than India for now" do
      allow(CountryConfig).to receive(:current).and_return({name: "Bangladesh"})
      expect {
        RegionBackfill.call(dry_run: false)
      }.to raise_error(RegionBackfill::UnsupportedCountry)
    end

    it "backfills" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "fg1", organization: org)
      facility_group_2 = create(:facility_group, name: "fg2", organization: org)
      _facility_group_3 = create(:facility_group, name: "fg3", organization: org)
      facility_group_4 = create(:facility_group, name: "fg4", organization: org)

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1, zone: "Block XYZ", state: "State 1")
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1, zone: "Block 123", state: "State 1")
      facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2, zone: "Block ZZZ", state: "State 2")
      facility_4 = create(:facility, name: "facility4", facility_group: facility_group_2, zone: "Block ZZZ", state: "State 2")
      facility_5 = create(:facility, name: "facility5", facility_group: facility_group_4, zone: "Block ABC", state: "State 1")
      facility_6 = create(:facility, name: "facility6", facility_group: facility_group_1, zone: "Block 123", state: "State 1")
      facilities = [facility_1, facility_2, facility_3, facility_4, facility_5, facility_6]

      RegionBackfill.call(dry_run: false)
      RegionBackfill.call(dry_run: false)

      root = Region.find_by(name: "India")
      expect(root.root?).to be true
      org = root.children.first
      expect(org.children.map(&:name)).to contain_exactly("State 1", "State 2")

      states = Region.state
      expect(states.count).to eq(2)
      expect(states.pluck(:slug)).to contain_exactly("state-1", "state-2")
      expect(states.pluck(:name)).to contain_exactly("State 1", "State 2")

      block_regions = Region.block
      expect(block_regions.size).to eq(4)
      expect(block_regions.map(&:name)).to contain_exactly("Block XYZ", "Block 123", "Block ZZZ", "Block ABC")

      facility_regions = Region.facility
      expect(facility_regions.size).to eq(6)

      expect(org.leaves.map(&:source)).to contain_exactly(*facilities)
      expect(org.leaves.map(&:region_type).uniq).to contain_exactly("facility")
    end

    it "establishes associations from facility / facility group back to regions" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org, state: "State 1")
      facility_group_2 = create(:facility_group, organization: org, state: "State 2")

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1, state: "State 1")
      _facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1, state: "State 2")
      _facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2, state: "State 3")

      RegionBackfill.call(dry_run: false)

      region_f1 = facility_1.region
      expect(region_f1).to_not be_nil
      expect(region_f1.name).to eq(facility_1.name)
      expect(region_f1.region_type).to eq("facility")

      expect(region_f1.parent.name).to eq(facility_1.zone)
      expect(region_f1.parent.region_type).to eq("block")

      expect(region_f1.parent.parent).to eq(facility_1.facility_group.region)
    end

    it "is idempotent and does not create same data multiple times" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "fg1", organization: org, state: "State 1")
      facility_group_2 = create(:facility_group, name: "fg2", organization: org, state: "State 2")
      _facility_group_3 = create(:facility_group, name: "fg3", organization: org, state: "State 1")
      facility_group_4 = create(:facility_group, name: "fg4", organization: org, state: "State 1")

      create(:facility, name: "facility1", facility_group: facility_group_1, zone: "Block XYZ", state: "State 1")
      create(:facility, name: "facility2", facility_group: facility_group_1, zone: "Block 123", state: "State 1")
      create(:facility, name: "facility3", facility_group: facility_group_2, zone: "Block ZZZ", state: "State 2")
      create(:facility, name: "facility4", facility_group: facility_group_2, zone: "Block ZZZ", state: "State 2")
      create(:facility, name: "facility5", facility_group: facility_group_4, zone: "Block ABC", state: "State 1")
      create(:facility, name: "facility6", facility_group: facility_group_1, zone: "Block 123", state: "State 1")

      3.times do
        RegionBackfill.call(dry_run: false)
      end

      expect(Region.root.count).to eq 1
      expect(Region.organization.count).to eq 1
      expect(Region.state.count).to eq 2
      expect(Region.district.count).to eq 4
      expect(Region.block.count).to eq 4
      expect(Region.facility.count).to eq 6
      expect(Region.count).to eq 18
    end
  end
end
