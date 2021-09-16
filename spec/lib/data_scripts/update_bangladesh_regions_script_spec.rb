require "rails_helper"
require_relative "../../../lib/data_scripts/update_bangladesh_regions_script"

describe UpdateBangladeshRegionsScript do
  let(:test_csv_path) { Rails.root.join("spec", "fixtures", "files", "bd_test_regions.csv") }

  before do
    Region.delete_all
    root = Region.create!(name: "Bangladesh", region_type: "root", path: "bangladesh")
    Region.create!(name: "NCDC, DGHS and NHF", region_type: :organization, slug: "nhf", reparent_to: root)
    expect(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return(true)
  end

  context "dry_run" do
    it "changes nothing in dry run mode" do
      create(:facility, facility_size: "community")
      expect {
        described_class.call(dry_run: true, csv_path: test_csv_path)
      }.to not_change { Facility.count }.and not_change { Region.count }
    end

    it "returns results" do
      create_list(:facility, 2, facility_size: "community")
      expect {
        results = described_class.call(dry_run: true, csv_path: test_csv_path)
        expect(results[:facilities_deleted]).to eq(2)
        expect(results[:facility_creates]).to eq(44)
        expect(results[:region_creates]).to eq(64)
        expect(results[:dry_run]).to be true
      }.to not_change { Facility.count }.and not_change { Region.count }
    end
  end

  context "region import" do
    it "creates new facilities from CSV" do
      result = nil
      expect {
        result = described_class.call(dry_run: false, csv_path: test_csv_path)
        expect(result[:region_creates]).to eq(63)
        expect(result[:facility_creates]).to eq(44)
      }.to change { Region.count }.by(63).and change { Facility.count }.by(44)
    end
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
      script = described_class.new(dry_run: false, csv_path: test_csv_path)
      expect(script).to receive(:create_facilities)
      script.call
    }.to change { Facility.count }.by(-2)
    empty_facilities.each do |facility|
      expect(Facility.find_by(id: facility.id)).to be_nil
    end
  end
end
