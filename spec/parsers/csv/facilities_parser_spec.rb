require "rails_helper"

RSpec.describe Csv::FacilitiesParser do
  describe ".parse" do
    let(:upload_file) { fixture_file_upload("files/upload_facilities_test.csv", "text/csv") }

    it "parses the facilities" do
      facilities = described_class.parse(upload_file)

      expect(facilities.first).to have_attributes(organization_name: "OrgOne",
        facility_group_name: "FGTwo",
        name: "Test Facility",
        facility_type: "CHC",
        district: "Bhatinda",
        country: "India",
        facility_size: "community",
        enable_diabetes_management: true)

      expect(facilities.second).to have_attributes(organization_name: "OrgOne",
        facility_group_name: "FGTwo",
        name: "Test Facility 2",
        facility_type: "CHC",
        district: "Bhatinda",
        facility_size: "large",
        country: "India")
    end

    it "defaults enable_diabetes_management to false if blank" do
      facilities = described_class.parse(upload_file)

      expect(facilities.second.enable_diabetes_management).to be false
    end

    it "sets the state" do
      create(:facility_group, name: "FGTwo", state: "Maharashtra", organization: create(:organization, name: "OrgOne"))

      facilities = described_class.parse(upload_file)

      expect(facilities.first).to have_attributes(organization_name: "OrgOne", facility_group_name: "FGTwo", state: "Maharashtra")
    end

    context "when provided localized facility sizes" do
      around do |example|
        I18n.with_locale(:en_IN) do
          example.run
        end
      end

      let(:upload_file) { fixture_file_upload("files/upload_facilities_test.csv", "text/csv") }

      it "parses the facilities" do
        facilities = described_class.parse(upload_file)

        expect(facilities.first.facility_size).to eq("community")
        expect(facilities.second.facility_size).to eq("large")
      end
    end
  end
end
