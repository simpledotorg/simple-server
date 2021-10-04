require "rails_helper"
require "tasks/scripts/chennai_hierarchy_cleanup"

RSpec.describe ChennaiHierarchyCleanup do
  it "doesn't run outside india prod" do
    expect { described_class.call }.to raise_error "Cannot run this outside India production"
  end

  it "doesn't run if Chennai district hasn't been created on dashboard" do
    stub_const("SIMPLE_SERVER_ENV", "production")

    expect { described_class.call }.to raise_error "Create Chennai district from dashboard before running"
  end

  it "reparents old blocks to the new district" do
    stub_const("SIMPLE_SERVER_ENV", "production")

    new_district = create(:facility_group, name: "Chennai", state: "Tamil Nadu")
    old_district = create(:facility_group, name: "Chennai old", state: "Tamil Nadu")
    block = create(:region, :block, name: "Chennai old - block", reparent_to: old_district.region)

    described_class.call

    expect(block.reload.district_region).to eq(new_district.region)
    expect(old_district.reload.deleted_at).to be_present
    expect(old_district.region).to be_nil
  end

  it "sync region ID of any facility remains unchanged" do
    stub_const("SIMPLE_SERVER_ENV", "production")

    new_district = create(:facility_group, name: "Chennai", state: "Tamil Nadu")
    old_district = create(:facility_group, name: "Chennai old", state: "Tamil Nadu")
    block = create(:region, :block, name: "Chennai old - block", reparent_to: old_district.region)
    facility = create(:facility, block: block.name, facility_group: old_district)

    described_class.call

    facility.reload

    expect(facility.region.block_region.id).to eq(block.id)
    expect(facility.region.district_region).to eq(new_district.region)
  end

  it "only one district remains in Tamil Nadu after the cleanup" do
    stub_const("SIMPLE_SERVER_ENV", "production")

    create(:facility_group, name: "Chennai", state: "Tamil Nadu")
    create_list(:facility_group, 2, name: "Chennai old", state: "Tamil Nadu")

    described_class.call
    expect(Region.state_regions.find_by(name: "Tamil Nadu").district_regions.count).to eq(1)
  end

  it "copies access from old facility groups to new facility group" do
    stub_const("SIMPLE_SERVER_ENV", "production")

    user = create(:admin, :viewer_all)
    organization = create(:organization)
    old_district = create(:facility_group, name: "Chennai old", state: "Tamil Nadu", organization: organization)
    new_district = create(:facility_group, name: "Chennai", state: "Tamil Nadu", organization: organization)

    create(:access, user: user, resource: old_district)

    described_class.call

    expect(Access.find_by(user: user, resource: new_district)).to be_present
  end
end
