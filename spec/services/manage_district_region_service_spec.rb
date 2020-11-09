require "rails_helper"

RSpec.describe ManageDistrictRegionService, type: :model do
  before do
    enable_flag(:regions_prep)
  end

  it "creates new blocks from new_blocks" do
    org = create(:organization, name: "IHCI")
    new_blocks = ["Block 1", "Block 2"]
    facility_group = create(:facility_group, name: "FG", state: "Punjab", organization: org)

    described_class.update_blocks(district_region: facility_group.region, new_blocks: new_blocks)

    expect(facility_group.region.blocks.pluck(:name)).to match_array new_blocks
    expect(facility_group.region.blocks.pluck(:path)).to contain_exactly("india.ihci.punjab.fg.block_1", "india.ihci.punjab.fg.block_2")
  end

  it "deletes blocks from remove_blocks" do
    block = facility_group.region.blocks.first
    facility_group.update(remove_blocks: [block.id])
    expect(facility_group.region.blocks).not_to include block
  end
end
