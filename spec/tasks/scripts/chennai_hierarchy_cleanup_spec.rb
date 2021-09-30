require "rails_helper"
require "tasks/scripts/chennai_hierarchy_cleanup"

describe "ChennaiHierarchyCleanup" do
  it "doesn't run outside india prod" do
    expect { ChennaiHierarchyCleanup.run }.to raise_error "Cannot run this outside India production"
  end

  it "doesn't run if Chennai district hasn't been created on dashboard" do
    stub_const("SIMPLE_SERVER_ENV", "production")

    expect { ChennaiHierarchyCleanup.run }.to raise_error "Create Chennai district before running"
  end

  it "reparents old blocks to the new district" do
    stub_const("SIMPLE_SERVER_ENV", "production")

    new_district = create(:facility_group, name: "Chennai", state: "Tamil Nadu")
    old_district = create(:facility_group, name: "Chennai old", state: "Tamil Nadu")
    block = create(:region, :block, name: "Chennai old - block", reparent_to: old_district.region)

    ChennaiHierarchyCleanup.run

    expect(block.reload.district_region).to eq(new_district.region)
    expect(old_district.reload.deleted_at).to be_present
    expect(old_district.region).to be_nil
  end

  it "sync region ID of any facility remains unchanged" do
  end

  it "only one district remains in Tamil Nadu after the cleanup" do
  end
end
