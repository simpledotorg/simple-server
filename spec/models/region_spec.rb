require "rails_helper"

RSpec.describe Region, type: :model do
  before do
    # duplicating this from the data migration for now
    instance = RegionKind.create! name: "Root", path: "Root"
    org = RegionKind.create! name: "Organization", parent: instance
    facility_group = RegionKind.create! name: "FacilityGroup", parent: org
    block = RegionKind.create! name: "Block", parent: facility_group
    _facility = RegionKind.create! name: "Facility", parent: block
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
