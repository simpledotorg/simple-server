require "rails_helper"
require "tasks/scripts/import_facility_block_names"

RSpec.describe ImportFacilityBlockNames do
  it "imports blocks for matching facilities and skip others" do
    fg = create(:facility_group, name: "Singapore")
    facility = create(:facility,
      name: "Facility 1",
      state: "Maharashtra",
      block: block.name,
      district: "Wardha",
      facility_group: fg)

    ImportFacilityBlockNames.import("spec/fixtures/files/facility_blocks_list.csv")
    expect(facility.reload.block).to eq("Block B")
  end
end
