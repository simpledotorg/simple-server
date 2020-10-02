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
    it "backfills" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      facility_group_2 = create(:facility_group, organization: org)

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1)
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)
      facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2)

      RegionBackfill.call(dry_run: false)

      root = Region.find_by(name: "India")
      expect(root.root?).to be true
      org = root.children.first
      expect(org.children.map(&:source)).to contain_exactly(facility_group_1, facility_group_2)

      block_regions = Region.where(type: RegionType.find_by!(name: "Block"))
      expect(block_regions.size).to eq(2)
      expect(block_regions.map(&:name).uniq).to eq(["Block ABC"])

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
      expect(region_f1.parent.parent).to eq(facility_1.facility_group.region)
      expect(region_f1.parent.parent.parent).to eq(facility_1.facility_group.organization.region)
    end
  end
end
