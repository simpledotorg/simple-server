require "rails_helper"

RSpec.describe Seed::UserSeeder do
  before do
    Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")
    org_name = "IHCI"
    Organization.find_by(name: org_name) || FactoryBot.create(:organization, name: org_name)
  end

  it "creates Users and associated authentication" do
    create_list(:facility, 5, facility_size: "community")

    config = Seed::Config.new
    expected_users_per_facility = config.max_number_of_users_per_facility
    facility_count = Facility.count
    expect {
      Seed::UserSeeder.call(config: config)
    }.to change { User.count }.by(expected_users_per_facility * facility_count)
      .and change { PhoneNumberAuthentication.count }.by(expected_users_per_facility * facility_count)
    User.all.each do |user|
      expect(user.phone_number_authentication).to_not be_nil
    end
    Facility.all.each do |facility|
      expect(facility.users.size).to eq(expected_users_per_facility)
    end
  end

end