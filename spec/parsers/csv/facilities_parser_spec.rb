require "rails_helper"

RSpec.describe Csv::FacilitiesParser do
  describe ".parse" do
    let(:upload_file) { file_fixture("upload_facilities_test.csv").read }

    it "parses the facilities" do
      facility_data_map = described_class.parse(upload_file)
      facilities = facility_data_map[:facilities]
      business_identifiers = facility_data_map[:business_identifiers]

      expect(facilities.first).to have_attributes(organization_name: "OrgOne",
        facility_group_name: "FGTwo",
        name: "Test Facility",
        facility_type: "CHC",
        district: "Bhatinda",
        country: "India",
        facility_size: "community",
        enable_diabetes_management: true,
        enable_monthly_screening_reports: true,
        enable_monthly_supplies_reports: true)

      expect(business_identifiers.first).to have_attributes(
        identifier: "id1",
        identifier_type: FacilityBusinessIdentifier.identifier_types[:external_org_facility_id],
        facility_id: facilities.first.id
      )

      expect(facilities.second).to have_attributes(organization_name: "OrgOne",
        facility_group_name: "FGTwo",
        name: "Test Facility 2",
        facility_type: "CHC",
        district: "Bhatinda",
        facility_size: "large",
        country: "India")
    end

    it "defaults enable_diabetes_management to false if blank" do
      facility_data_map = described_class.parse(upload_file)

      expect(facility_data_map[:facilities].second.enable_diabetes_management).to be false
    end

    it "sets the state" do
      create(:facility_group, name: "FGTwo", state: "Maharashtra", organization: create(:organization, name: "OrgOne"))

      facility_data_map = described_class.parse(upload_file)

      expect(facility_data_map[:facilities].first).to have_attributes(
        organization_name: "OrgOne",
        facility_group_name: "FGTwo",
        state: "Maharashtra"
      )
    end

    context "when provided localized facility sizes" do
      around do |example|
        I18n.with_locale("en-IN") do
          example.run
        end
      end

      let(:upload_file) { file_fixture("upload_facilities_test.csv").read }

      it "parses the facilities" do
        facilities = described_class.parse(upload_file)[:facilities]

        expect(facilities.first.facility_size).to eq("community")
        expect(facilities.second.facility_size).to eq("large")
      end
    end
  end
end
