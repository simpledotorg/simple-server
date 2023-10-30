require "rails_helper"

RSpec.describe Csv::FacilitiesParser do
  describe ".parse" do
    let(:upload_file) { file_fixture("upload_facilities_test.csv").read }

    it "parses the facilities" do
      org = create(:organization, name: "OrgOne")

      first_facility, second_facility, *_facilities = described_class.parse(upload_file)

      expect(first_facility[:facility]).to have_attributes(organization_name: "OrgOne",
        facility_group_name: "FGTwo",
        name: "Test Facility",
        facility_type: "CHC",
        district: "Bhatinda",
        country: "India",
        facility_size: "community",
        enable_diabetes_management: true,
        enable_monthly_screening_reports: true,
        enable_monthly_supplies_reports: true)

      expect(first_facility[:business_identifiers].first).to have_attributes(
        identifier: "id1",
        identifier_type: "external_org_facility_id:#{org.id}",
        facility_id: first_facility[:facility].id
      )

      expect(second_facility[:facility]).to have_attributes(organization_name: "OrgOne",
        facility_group_name: "FGTwo",
        name: "Test Facility 2",
        facility_type: "CHC",
        district: "Bhatinda",
        facility_size: "large",
        country: "India")

      expect(second_facility[:business_identifiers]).to be_empty
    end

    it "defaults enable_diabetes_management to false if blank" do
      create(:organization, name: "OrgOne")
      _, second_facility, *_facilities = described_class.parse(upload_file)

      expect(second_facility[:facility].enable_diabetes_management).to be false
    end

    it "sets the state" do
      create(:facility_group, name: "FGTwo", state: "Maharashtra", organization: create(:organization, name: "OrgOne"))

      first_facility, *_facilities = described_class.parse(upload_file)

      expect(first_facility[:facility]).to have_attributes(
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
        create(:organization, name: "OrgOne")

        first_facility, second_facility, *_facilities = described_class.parse(upload_file)

        expect(first_facility[:facility].facility_size).to eq("community")
        expect(second_facility[:facility].facility_size).to eq("large")
      end
    end
  end
end
