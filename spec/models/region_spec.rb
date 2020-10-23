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
    it "sets a valid path" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "District XYZ", organization: org)
      facility_1 = create(:facility, name: "facility UHC (ZZZ)", state: "Test State", block: "Block22", facility_group: facility_group_1)
      long_name = ("This is a long facility name" * 10)
      long_path = long_name.gsub(/\W/, "_").slice(0, Region::MAX_LABEL_LENGTH)
      facility_2 = create(:facility, name: long_name, block: "Block22", state: "Test State", facility_group: facility_group_1)

      RegionBackfill.call(dry_run: false)

      expect(org.region.path).to eq("India.Test_Organization")
      expect(facility_group_1.region.path).to eq("India.Test_Organization.Test_State.District_XYZ")
      expect(facility_1.region.path).to eq("India.Test_Organization.Test_State.District_XYZ.#{facility_1.block}.Facility_UHC__ZZZ_")
      expect(facility_2.region.path).to eq("India.Test_Organization.Test_State.District_XYZ.#{facility_1.block}.#{long_path}")
    end

    it "can soft delete nodes" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      facility_group_2 = create(:facility_group, organization: org)

      _facility_1 = create(:facility, name: "facility1", state: "State 1", facility_group: facility_group_1)
      _facility_2 = create(:facility, name: "facility2", state: "State 2", facility_group: facility_group_2)

      RegionBackfill.call(dry_run: false)

      state_2 = Region.find_by!(name: "State 2")
      expect(state_2.children).to_not be_empty
      expect(facility_group_2.reload.region).to_not be_nil

      facility_group_2.discard
      # Ensure that facility group 2's region is discarded with it and no longer in the tree
      expect(facility_group_2.region.path).to be_nil
      expect(facility_group_2.region.parent).to be_nil
      expect(org.region.children.map(&:name)).to contain_exactly("State 1", "State 2")
      expect(state_2.children).to be_empty
    end
  end
end
