require "rails_helper"

RSpec.describe Seed::FacilitySeeder do
  it "creates facility groups and facilities" do
    expect {
      Seed::FacilitySeeder.call(config: Seed::Config.new)
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by_at_most(8)
      .and change { User.count }.by_at_most(16)
  end

  it "does not create more facility groups than the max when called multiple times" do
    expect {
      4.times { Seed::FacilitySeeder.call(config: Seed::Config.new) }
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by_at_most(8)
  end
end