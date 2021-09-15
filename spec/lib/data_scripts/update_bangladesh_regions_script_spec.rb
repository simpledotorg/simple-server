require "rails_helper"
require_relative "../../../lib/data_scripts/update_bangladesh_regions_script"

describe UpdateBangladeshRegionsScript do
  it "runs" do
    described_class.call
  end

  it "changes nothing in dry run mode" do
    expect {
      described_class.call
    }.to not_change { Facility.count }.and not_change { Region.count }
  end

  it "removes Facilities without patients and users" do
    expect(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return(true)
    other_facility = create(:facility)
    user = create(:user, registration_facility: other_facility)
    empty_facilities = create_list(:facility, 2, facility_size: "community")
    large_empty_facility = create(:facility, facility_size: "large")
    assigned_facility = create(:facility)
    registration_facility = create(:facility)
    create(:patient, registration_facility: registration_facility, assigned_facility: other_facility, registration_user: user)
    create(:patient, registration_facility: other_facility, assigned_facility: assigned_facility, registration_user: user)

    expect {
      described_class.call(dry_run: false)
    }.to change { Facility.count }.by(-2)
    empty_facilities.each do |facility|
      expect(Facility.find_by(id: facility.id)).to be_nil
    end
  end
end