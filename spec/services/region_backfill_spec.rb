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

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1, zone: "Zone XYZ", state: "State 1")
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1, zone: "Zone 123", state: "State 1")
      facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2, zone: "Zone ZZZ", state: "State 2")

      RegionBackfill.call(dry_run: false)

      root = Region.find_by(name: "India")
      expect(root.root?).to be true
      org = root.children.first
      expect(org.children.map(&:name)).to contain_exactly("State 1", "State 2")

      states = Region.where(type: RegionType.find_by(name: "State"))
      expect(states.count).to eq(2)
      expect(states.pluck(:name)).to contain_exactly("State 1", "State 2")

      zone_regions = Region.where(type: RegionType.find_by!(name: "Zone"))
      expect(zone_regions.size).to eq(3)
      expect(zone_regions.map(&:name)).to contain_exactly("Zone XYZ", "Zone 123", "Zone ZZZ")

      expect(org.leaves.map(&:source)).to contain_exactly(facility_1, facility_2, facility_3)
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
      expect(region_f1.parent.type.name).to eq("Zone")

      expect(region_f1.parent.parent).to eq(facility_1.facility_group.region)
    end
  end
end
