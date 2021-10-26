require "rails_helper"
require_relative "../../../lib/data_scripts/update_bangladesh_regions_script"

describe UpdateBangladeshRegionsScript do
  let(:test_csv_path) { Rails.root.join("spec", "fixtures", "files", "bd_test_regions.csv") }
  let(:facility_group) { create(:facility_group, name: "Brooklyn District") }

  context "non Bangladesh deployments" do
    it "does nothing in other countries" do
      expect(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return(false)
      expect {
        described_class.new(dry_run: false, csv_path: test_csv_path)
      }.to raise_error(SystemExit, "Error - aborting! This script only runs in Bangladesh")
    end
  end

  context "in Bangladesh deployment" do
    before do
      Region.delete_all
      root = Region.create!(name: "Bangladesh", region_type: "root", path: "bangladesh")
      org_region = Region.create!(name: "NCDC, DGHS and NHF", region_type: :organization, slug: "nhf", reparent_to: root)
      _org = Organization.create!(name: "NHF", region: org_region)
      _protocol = create(:protocol, name: "Bangladesh Hypertension Management Protocol for Primary Healthcare Setting")
      jamalpur = create(:facility_group, name: "Jamalpur District", state: "Myemsing")
      facility = create(:facility, name: "UHC Melandah", block: "Melandah", district: "Jamalpur District", facility_group: jamalpur)
      facility.business_identifiers.create!(identifier_type: :dhis2_org_unit_id, identifier: "55555")
      expect(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return(true)
    end

    context "dry_run" do
      it "changes nothing in dry run mode" do
        create(:facility, facility_size: "community")
        expect {
          described_class.call(dry_run: true, csv_path: test_csv_path)
        }.to not_change { Facility.count }
          .and not_change { FacilityGroup.count }
          .and not_change { Region.count }
          .and not_change { User.count }
      end

      it "returns results" do
        create_list(:facility, 2, facility_size: "community")
        expect {
          results = described_class.call(dry_run: true, csv_path: test_csv_path)
          # we expect some of the blocks to rename to be missing in our test data set
          results[:errors].except(:block_rename_missing).each { |type, count| expect(count).to eq(0) }
          expect(results[:deleted][:facilities]).to eq(2)
          expect(results[:created][:facilities]).to eq(45)
          expect(results[:created][:facility_regions]).to eq(45)
          expect(results[:dry_run]).to be true
        }.to not_change { Facility.count }.and not_change { Region.count }
      end
    end

    context "write mode" do
      it "creates new regions, facilities, and facility groups from CSV" do
        expect {
          result = described_class.call(dry_run: false, csv_path: test_csv_path)
          # we expect some of the blocks to rename to be missing in our test data set
          result[:errors].except(:block_rename_missing).each { |type, count| expect(count).to eq(0) }
          expect(result[:created][:facility_regions]).to eq(45)
          expect(result[:created][:facilities]).to eq(45)
          expect(result[:updates][:block_rename]).to eq(1)
        }.to change { Region.count }.by(66)
          .and change { Region.facility_regions.count }.by(45)
          .and change { Region.district_regions.count }.by(6)
          .and change { Facility.count }.by(45)
          .and change { FacilityGroup.count }.by(6)

        missing_regions = (Facility.pluck(:id).to_set - Region.facility_regions.pluck(:source_id).to_set).to_a
        expect(missing_regions).to be_empty
        Facility.all.eager_load(:business_identifiers).each do |facility|
          expect(facility.region).to_not be_nil
          expect(facility.business_identifiers.size).to eq(1)
          fg = facility.facility_group
          expect(fg).to_not be_nil
          expect(fg.name).to eq(fg.region.name)
          expect(fg.region).to_not be_nil
        end
        # Spot check a facility
        #  Sylhet,Sunamganj,Bishwambarpur,Dhonpur,Halabadi Cc ,10012777,CC Halabadi ,CC,,,,,,,,,,,,,,,,
        facility = Facility.find_by!(name: "CC Halabadi")
        expect(facility.facility_type).to eq("CC")
        expect(facility.facility_size).to eq("community")
        expect(facility.business_identifiers.find_by!(identifier_type: :dhis2_org_unit_id).identifier).to eq("10012777")
        expect(facility.state).to eq("Sylhet")
        expect(facility.district).to eq("Sunamganj")
        expect(facility.block).to eq("Bishwambarpur")
        expect(facility.region.state_region.name).to eq("Sylhet")
        expect(facility.region.district_region.name).to eq("Sunamganj")
        expect(facility.region.block_region.name).to eq("Bishwambarpur")
        check = RegionsIntegrityCheck.sweep
        check.inconsistencies.each { |region_type, problems|
          expect(problems).to be_empty
        }
      end

      it "removes community & unsized Facilities without patients" do
        other_facility = create(:facility, facility_group: facility_group)
        user = create(:user, registration_facility: other_facility)
        empty_facilities = create_list(:facility, 2, facility_size: "community")
        empty_facility_with_no_size = create(:facility, facility_size: nil, facility_group: facility_group)
        empty_facility_user = create(:user, registration_facility: empty_facility_with_no_size)
        user_with_multiple_facility_access = create(:user, registration_facility: empty_facility_with_no_size)
        phone_number_authentication = create(:phone_number_authentication, facility: other_facility, user: user_with_multiple_facility_access)
        user_with_multiple_facility_access.user_authentications << UserAuthentication.new(authenticatable: phone_number_authentication)
        _large_empty_facility = create(:facility, facility_size: "large")
        assigned_facility = create(:facility)
        registration_facility = create(:facility)
        create(:patient, registration_facility: registration_facility, assigned_facility: other_facility, registration_user: user)
        create(:patient, registration_facility: other_facility, assigned_facility: assigned_facility, registration_user: user)

        deleted_block_count = (empty_facilities << empty_facility_with_no_size).map(&:block_region).uniq.count
        deleted_region_count = deleted_block_count + 3 + 2 # 3 facilities, 2 districts
        expect {
          script = described_class.new(dry_run: false, csv_path: test_csv_path)
          expect(script).to receive(:import_from_csv)
          script.call
        }.to change { Facility.count }.by(-3)
          .and change { FacilityGroup.count }.by(-2)
          .and change { Region.block_regions.count }.by(-deleted_block_count)
          .and change { Region.count }.by(-deleted_region_count)
          .and change { User.count }.by(-1)
        empty_facilities.each do |facility|
          expect(Facility.find_by(id: facility.id)).to be_nil
        end
        expect(User.find_by(id: empty_facility_user)).to be_nil
        expect(User.find_by(id: user_with_multiple_facility_access)).to_not be_nil
      end
    end
  end
end
