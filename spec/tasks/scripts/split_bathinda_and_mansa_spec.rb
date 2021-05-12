require "rails_helper"
require "tasks/scripts/split_bathinda_and_mansa"

RSpec.describe SplitBathindaAndMansa do
  let!(:organization) { create(:organization) }
  let!(:bathinda_and_mansa) { create(:facility_group, name: "Bathinda and Mansa", organization: organization, state: "Punjab") }
  let!(:bathinda) { create(:facility_group, name: "Bathinda", organization: organization, state: "Punjab") }
  let!(:mansa) { create(:facility_group, name: "Mansa", organization: organization, state: "Punjab") }
  let!(:facilities) {
    [create(:facility, district: "Bathinda", block: "Bathinda block", facility_group: bathinda_and_mansa),
      create(:facility, district: "Mansa", block: "Mansa block", facility_group: bathinda_and_mansa)]
  }

  it "sets the facility group on the facilities" do
    described_class.call

    expect(bathinda_and_mansa.facilities.count).to eq 0
    expect(bathinda.facilities.count).to eq 1
    expect(mansa.facilities.count).to eq 1
  end

  it "doesn't change the sync_region_id (block id) of the facilities" do
    original_blocks = facilities.map(&:block)
    described_class.call

    new_blocks = facilities.map(&:reload).map(&:block)
    expect(new_blocks).to eq original_blocks
  end

  it "reparents the block regions correctly" do
    described_class.call

    facilities.map(&:reload)
    expect(facilities.first.region.block_region.parent).to eq bathinda.region
    expect(facilities.second.region.block_region.parent).to eq mansa.region
  end

  it "reparents the facility regions correctly" do
    described_class.call

    facilities.map(&:reload)
    expect(facilities.first.region.district_region).to eq bathinda.region
    expect(facilities.second.region.district_region).to eq mansa.region
  end
end
