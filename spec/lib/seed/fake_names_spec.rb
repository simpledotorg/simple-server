require "rails_helper"

RSpec.describe Seed::FakeNames do
  it "can return fake village names" do
    fake_names = Seed::FakeNames.instance
    possible_village_names = fake_names._csv["Villages/Cities"]
    expect(possible_village_names).to include(fake_names.village_name)
  end

  it "can return fake org names" do
    fake_names = Seed::FakeNames.instance
    org_names = fake_names._csv["Organizations"]
    expect(org_names).to include(fake_names.org_name)
  end

  it "can return consisent org name for dev" do
    fake_names = Seed::FakeNames.instance
    org_names = fake_names._csv["Organizations"]
    expect(org_names).to include(fake_names.standard_dev_org_name)
    expect(org_names.first).to eq(fake_names.standard_dev_org_name)
  end
end
