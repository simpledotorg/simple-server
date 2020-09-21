require "rails_helper"

RSpec.describe Region, type: :model do
  before do
    # duplicating this from the data migration for now
    instance = RegionKind.create! name: "Instance", path: "Instance"
    org = RegionKind.create! name: "Organization", parent: instance
    facility_group = RegionKind.create! name: "FacilityGroup", parent: org
    block = RegionKind.create! name: "Block", parent: facility_group
    _facility = RegionKind.create! name: "Facility", parent: block
  end

  it "backfills" do
    pp RegionKind.all
    org = create(:organization, name: "Test Organization")
    facility_group_1 = create(:facility_group, organization: org)
    facility_group_2 = create(:facility_group, organization: org)

    facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1)
    facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)

    facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2)

    Region.backfill!

    root = Region.find_by(name: "India")
    expect(root.root?).to be true
    org = root.children.first
    expect(org.children.map(&:source)).to contain_exactly(facility_group_1, facility_group_2)

    pp "descendants ->"
    pp org.descendants
    pp org.leaves

    block_regions = Region.where(kind: RegionKind.find_by!(name: "Block"))
    expect(block_regions.size).to eq(2)
    expect(block_regions.map(&:name).uniq).to eq(["Block ABC"])

    expect(org.leaves.map(&:source)).to contain_exactly(facility_1, facility_2, facility_3)
    expect(org.leaves.map(&:kind).uniq).to contain_exactly(RegionKind.find_by!(name: "Facility"))
  end

  it "can soft delete nodes" do
    org = create(:organization, name: "Test Organization")
    facility_group_1 = create(:facility_group, organization: org)
    facility_group_2 = create(:facility_group, organization: org)

    facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1)
    facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)

    Region.backfill!

    facility_group_2.discard
    expect(facility_group_2.region.reload.path).to be_nil
    expect(org.region.children.map(&:source)).to contain_exactly(facility_group_1)
  end
end
