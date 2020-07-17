require "rails_helper"

RSpec.describe StateRegionCreator, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_group_2) { FactoryBot.create(:facility_group, name: "facility_group_2", organization: organization) }
  let(:facility_group_3) { FactoryBot.create(:facility_group, name: "facility_group_3", organization: organization) }

  it "creates Regions for all states from Facilities" do
    facility_1 = create(:facility, state: "state-1")
    facility_2 = create(:facility, state: "state-1")
    facility_3 = create(:facility, state: "state-2")
    StateRegionCreator.new.call
    expect(Region.state.size).to eq(2)
    expect(Region.state.map(&:name)).to contain_exactly("state-1", "state-2")
  end

  it "assigns Organization as parent region" do
    facility_1 = create(:facility, state: "state-1", facility_group: facility_group_1)
    facility_2 = create(:facility, state: "state-1", facility_group: facility_group_1)
    facility_3 = create(:facility, state: "state-1", facility_group: facility_group_3)

    facility_4 = create(:facility, state: "state-2", facility_group: facility_group_2)
    StateRegionCreator.new.call
    Region.state.each do |region|
      expect(region.parent_region).to eq(organization)
    end
  end

  it "creates Regions inside the appropriate FacilityGroup" do
    facility_1 = create(:facility, state: "state-1", facility_group: facility_group_1)
    facility_2 = create(:facility, state: "state-1", facility_group: facility_group_1)
    facility_3 = create(:facility, state: "state-1", facility_group: facility_group_3)

    facility_4 = create(:facility, state: "state-2", facility_group: facility_group_2)
    StateRegionCreator.new.call
    expect(Region.state.size).to eq(2)
    expect(Region.state.map(&:name)).to contain_exactly("state-1", "state-2")

    region_1 = facility_group_1.reload.parent_region
    expect(region_1.name).to eq("state-1")
    expect(region_1.children).to contain_exactly(facility_group_1, facility_group_3)

    region_2 = facility_group_2.reload.parent_region
    expect(region_2.children).to contain_exactly(facility_group_2)
  end
end