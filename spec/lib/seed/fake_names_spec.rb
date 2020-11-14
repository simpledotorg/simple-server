require "rails_helper"

RSpec.describe Seed::FakeNames do
  it "can return fake village names" do
    fake_names = Seed::FakeNames.instance
    possible_village_names = fake_names._csv["Villages/Cities"]
    expect(possible_village_names).to include(fake_names.village_name)
  end
end
