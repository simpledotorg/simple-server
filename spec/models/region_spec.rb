require "rails_helper"

RSpec.describe Region, type: :model do
  context "validations" do
    it "requires a region type" do
      region = Region.new(name: "foo", path: "foo")
      expect(region).to_not be_valid
      expect(region.errors[:type]).to eq(["must exist"])
    end
  end

  context "behavior" do
    before do
      instance = RegionType.create! name: "Root", path: "Root"
      org = RegionType.create! name: "Organization", parent: instance
      facility_group = RegionType.create! name: "FacilityGroup", parent: org
      block = RegionType.create! name: "Block", parent: facility_group
      _facility = RegionType.create! name: "Facility", parent: block
    end

    it "sets a valid path" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "District XYZ", organization: org)
      facility_1 = create(:facility, name: "facility UHC (ZZZ)", zone: "Block22", facility_group: facility_group_1)
      long_name = ("This is a long facility name" * 10)
      long_path = long_name.gsub(/\W/, "_").slice(0, Region::MAX_LABEL_LENGTH)
      facility_2 = create(:facility, name: long_name, zone: "Block22", facility_group: facility_group_1)

      RegionBackfill.call(dry_run: false)

      expect(org.region.path).to eq("India.Test_Organization")
      expect(facility_group_1.region.path).to eq("India.Test_Organization.District_XYZ")
      expect(facility_1.region.path).to eq("India.Test_Organization.District_XYZ.#{facility_1.zone}.Facility_UHC__ZZZ_")
      expect(facility_2.region.path).to eq("India.Test_Organization.District_XYZ.#{facility_1.zone}.#{long_path}")
    end

    it "can soft delete nodes" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      facility_group_2 = create(:facility_group, organization: org)

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1)
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)

      RegionBackfill.call(dry_run: false)

      facility_group_2.discard
      expect(facility_group_2.region.reload.path).to be_nil
      expect(org.region.children.map(&:source)).to contain_exactly(facility_group_1)
    end
  end
end
