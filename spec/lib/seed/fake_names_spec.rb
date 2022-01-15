require "rails_helper"

RSpec.describe Seed::FakeNames do
  it "can return fake village names" do
    fake_names = Seed::FakeNames.instance
    possible_village_names = fake_names._csv["Villages/Cities"]
    expect(possible_village_names).to include(fake_names.village)
  end

  it "can return fake org names" do
    fake_names = Seed::FakeNames.instance
    org_names = fake_names._csv["Organizations"]
    expect(org_names).to include(fake_names.organization)
  end

  it "can return consistent org name for the seed org" do
    fake_names = Seed::FakeNames.instance
    org_names = fake_names._csv["Organizations"]
    expect(org_names).to include(fake_names.seed_org_name)
    expect(org_names.first).to eq(fake_names.seed_org_name)
  end

  it "can get a large number of block names" do
    inst = described_class.instance
    names = 200.times.each_with_object([]) do |n, sum|
      sum.concat(inst.blocks.sample(3))
    end
    expect(names.size).to eq(600)
  end
end
