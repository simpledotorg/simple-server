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
      facility_group_3 = create(:facility_group, name: "fg3", organization: org)
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

      states = Region.where(type: RegionType.find_by(name: "State"))
      expect(states.count).to eq(2)
      expect(states.pluck(:slug)).to contain_exactly("state-1", "state-2")
      expect(states.pluck(:name)).to contain_exactly("State 1", "State 2")

      block_regions = Region.where(type: RegionType.find_by!(name: "Block"))
      expect(block_regions.size).to eq(4)
      expect(block_regions.map(&:name)).to contain_exactly("Block XYZ", "Block 123", "Block ZZZ", "Block ABC")

      facility_regions = Region.where(type: RegionType.find_by!(name: "Facility"))
      expect(facility_regions.size).to eq(6)
      expect(facility_regions.map(&:slug)).to contain_exactly(*facilities.map(&:slug))

      expect(org.leaves.map(&:source)).to contain_exactly(facility_1, facility_2, facility_3, facility_4, facility_5, facility_6)
      expect(org.leaves.map(&:type).uniq).to contain_exactly(RegionType.find_by!(name: "Facility"))
    end

    it "establishes associations from facility / facility group back to regions" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      facility_group_2 = create(:facility_group, organization: org)

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1)
      _facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)
      _facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2)

      RegionBackfill.call(dry_run: false)

      region_f1 = facility_1.region
      expect(region_f1).to_not be_nil
      expect(region_f1.name).to eq(facility_1.name)
      expect(region_f1.type.name).to eq("Facility")

      expect(region_f1.parent.name).to eq(facility_1.zone)
      expect(region_f1.parent.type.name).to eq("Block")

      expect(region_f1.parent.parent).to eq(facility_1.facility_group.region)
    end
  end
end
