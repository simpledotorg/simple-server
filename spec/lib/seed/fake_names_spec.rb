# frozen_string_literal: true

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
end
