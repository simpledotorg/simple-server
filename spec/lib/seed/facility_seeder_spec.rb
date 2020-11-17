require "rails_helper"

RSpec.describe Seed::FacilitySeeder do
  it "creates facility groups and facilities" do
    expect {
      Seed::FacilitySeeder.call(config: Seed::Config.new)
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by(8)
  end

  it "generates a name based on the facility size" do
    seeder = Seed::FacilitySeeder.new(config: Seed::Config.new)
    expect(seeder).to receive(:weighted_facility_size_sample).and_return(:small).at_least(1).times
    seeder.call
    small_facility_names = Regexp.union(Seed::FacilitySeeder::SIZES_TO_TYPE[:small])
    Facility.all.each do |facility|
      expect(facility.name).to match(small_facility_names)
    end
  end

  it "does not create more facility groups than the max when called multiple times" do
    expect {
      3.times { Seed::FacilitySeeder.call(config: Seed::Config.new) }
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by_at_most(8)
  end
end
