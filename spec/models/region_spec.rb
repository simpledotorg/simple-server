require "rails_helper"

RSpec.describe Region, type: :model do
  it "can be a state" do
    region = Region.new
    region.level = :state
    expect(region.level).to eq("state")
  end

  it "is the top of the hiearchy if its own parent" do
    region = Region.new(name: "top", level: :organization, parent_region: nil)

    region.save!
    expect(region.parent_region).to be_nil
    expect(region.top_level?).to be_truthy
  end

  it "can be parent of many children" do
    region = Region.new(name: "top", level: :organization)

    region.save!
    expect(region.top_level?).to be_truthy

    child1 = Region.create!(name: "child1", level: :state, parent_region: region)
    child2 = Region.create!(name: "child2", level: :state, parent_region: region)

    expect(region.children).to contain_exactly(child1, child2)
  end

  it "can be a parent of facility groups" do
    region = Region.new(name: "state", level: :state)
    facility_group_1 = create(:facility_group, parent_region: region)
    facility_group_2 = create(:facility_group, parent_region: region)
    expect(region.children).to contain_exactly(facility_group_1, facility_group_2)
  end

  it "can build a hiearchy" do
    org = create(:organization)

    state1 = create(:region, level: :state, parent_region: org)
    state2 = create(:region, level: :state, parent_region: org)

    fg1 = create(:facility_group, parent_region: state1)
    fg2 = create(:facility_group, parent_region: state1)

    fg3 = create(:facility_group, parent_region: state2)

    expect(org.children).to contain_exactly(state1, state2)
    expect(state1.parent_region).to eq(org)

    expect(fg1.parent_region).to eq(state1)
    expect(fg2.parent_region).to eq(state1)
    expect(state1.children).to contain_exactly(fg1, fg2)

    expect(fg3.parent_region).to eq(state2)
    expect(state2.children).to contain_exactly(fg3)
  end
end
