require "rails_helper"
require_relative "../../../lib/data_scripts/update_bangladesh_regions_script"

describe UpdateBangladeshRegionsScript do
  it "runs" do
    described_class.call
  end

  before do
    expect(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return(true)
  end

  it "changes nothing in dry run mode" do
    create(:facility, facility_size: "community")
    expect {
      described_class.call(dry_run: true)
    }.to not_change { Facility.count }.and not_change { Region.count }
  end

  context "region import" do
    before do
      Region.delete_all
      root = Region.create!(name: "Bangladesh", region_type: "root", path: "bangladesh")
      Region.create!(name: "NCDC, DGHS and NHF", region_type: :organization, slug: "nhf", reparent_to: root)
    end

    fit "creates new facilities from CSV" do
      pp Region.root_regions
      expect {
        described_class.call(dry_run: false)
      }.to change { Region.count }.by(3).and change { Facility.count }.by(1)
    end
  end

  it "returns results" do
    create_list(:facility, 2, facility_size: "community")
    results = described_class.call(dry_run: false)
    expect(results[:facilities_deleted]).to eq(2)
    expect(results[:dry_run]).to be false
  end

  it "removes Facilities without patients and users" do
    other_facility = create(:facility)
    user = create(:user, registration_facility: other_facility)
    empty_facilities = create_list(:facility, 2, facility_size: "community")
    _large_empty_facility = create(:facility, facility_size: "large")
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