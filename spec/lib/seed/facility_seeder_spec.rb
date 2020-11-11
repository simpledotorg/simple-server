require "rails_helper"

RSpec.describe Seed::FacilitySeeder do
  it "creates facility groups and facilities" do
    expected_users_per_facility = 1
    expect {
      Seed::FacilitySeeder.call(config: Seed::Config.new)
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by(8)
      .and change { User.count }.by(expected_users_per_facility * 8) # hard coding one user per facility for now
      .and change { PhoneNumberAuthentication.count }.by(expected_users_per_facility * 8)
    User.all.each do |user|
      expect(user.phone_number_authentication).to_not be_nil
    end
    Facility.all.each do |facility|
      expect(facility.users.size).to eq(expected_users_per_facility)
    end
  end

  it "does not create more facility groups than the max when called multiple times" do
    expect {
      4.times { Seed::FacilitySeeder.call(config: Seed::Config.new) }
    }.to change { FacilityGroup.count }.by(2)
      .and change { Facility.count }.by_at_most(8)
  end
end