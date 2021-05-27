require "rails_helper"
require "tasks/scripts/split_bathinda_and_mansa"

RSpec.describe SplitBathindaAndMansa do
  it "creates an access to the new FGs for users who had access to Bathinda and Mansa" do
    user = create(:admin, :viewer_all)
    organization = create(:organization)
    bathinda_and_mansa = create(:facility_group, name: "Bathinda and Mansa", organization: organization, state: "Punjab")
    bathinda = create(:facility_group, name: "Bathinda", organization: organization, state: "Punjab")
    mansa = create(:facility_group, name: "Mansa", organization: organization, state: "Punjab")

    create(:access, user: user, resource: bathinda_and_mansa)
    described_class.call

    expect(Access.find_by(user: user, resource: bathinda)).to be_present
    expect(Access.find_by(user: user, resource: mansa)).to be_present
  end

  it "sets the facility group on the facilities" do
    organization = create(:organization)
    bathinda_and_mansa = create(:facility_group, name: "Bathinda and Mansa", organization: organization, state: "Punjab")
    bathinda = create(:facility_group, name: "Bathinda", organization: organization, state: "Punjab")
    mansa = create(:facility_group, name: "Mansa", organization: organization, state: "Punjab")
    _facilities =
      [create(:facility, district: "Bathinda", block: "Bathinda block", facility_group: bathinda_and_mansa),
        create(:facility, district: "Mansa", block: "Mansa block", facility_group: bathinda_and_mansa)]

    described_class.call

    expect(bathinda_and_mansa.facilities.count).to eq 0
    expect(bathinda.facilities.count).to eq 1
    expect(mansa.facilities.count).to eq 1
  end

  it "doesn't change the sync_region_id (block id) of the facilities" do
    organization = create(:organization)
    bathinda_and_mansa = create(:facility_group, name: "Bathinda and Mansa", organization: organization, state: "Punjab")
    _bathinda = create(:facility_group, name: "Bathinda", organization: organization, state: "Punjab")
    _mansa = create(:facility_group, name: "Mansa", organization: organization, state: "Punjab")
    facilities =
      [create(:facility, district: "Bathinda", block: "Bathinda block", facility_group: bathinda_and_mansa),
        create(:facility, district: "Mansa", block: "Mansa block", facility_group: bathinda_and_mansa)]

    original_blocks = facilities.map(&:block)
    described_class.call

    new_blocks = facilities.map(&:reload).map(&:block)
    expect(new_blocks).to eq original_blocks
  end

  it "reparents the block regions correctly" do
    organization = create(:organization)
    bathinda_and_mansa = create(:facility_group, name: "Bathinda and Mansa", organization: organization, state: "Punjab")
    bathinda = create(:facility_group, name: "Bathinda", organization: organization, state: "Punjab")
    mansa = create(:facility_group, name: "Mansa", organization: organization, state: "Punjab")
    facilities =
      [create(:facility, district: "Bathinda", block: "Bathinda block", facility_group: bathinda_and_mansa),
        create(:facility, district: "Mansa", block: "Mansa block", facility_group: bathinda_and_mansa)]

    described_class.call

    facilities.map(&:reload)

    bathinda_facility_region = facilities.first.region
    mansa_facility_region = facilities.second.region

    expect(bathinda_facility_region.block_region.parent).to eq bathinda.region
    expect(mansa_facility_region.block_region.parent).to eq mansa.region
  end

  it "reparents the facility regions correctly" do
    organization = create(:organization)
    bathinda_and_mansa = create(:facility_group, name: "Bathinda and Mansa", organization: organization, state: "Punjab")
    bathinda = create(:facility_group, name: "Bathinda", organization: organization, state: "Punjab")
    mansa = create(:facility_group, name: "Mansa", organization: organization, state: "Punjab")
    facilities =
      [create(:facility, district: "Bathinda", block: "Bathinda block", facility_group: bathinda_and_mansa),
        create(:facility, district: "Mansa", block: "Mansa block", facility_group: bathinda_and_mansa)]

    described_class.call

    facilities.map(&:reload)

    bathinda_facility_region = facilities.first.region
    mansa_facility_region = facilities.second.region

    expect(bathinda_facility_region.district_region).to eq bathinda.region
    expect(mansa_facility_region.district_region).to eq mansa.region
  end
end
