require "rails_helper"
require "tasks/scripts/import_facility_block_names"

RSpec.describe ImportFacilityBlockNames do
  it "imports blocks for matching facilities and skip others" do
    fg = create(:facility_group, name: "Singapore")
    create(:region, :block, name: "Block B", reparent_to: fg.region)
    f = create(:facility, name: "Facility 1", state: "Maharashtra", district: "Wardha", facility_group: fg)

    ImportFacilityBlockNames.import("spec/fixtures/files/facility_blocks_list.csv")
    expect(f.reload.block).to eq("Block B")
  end
end
