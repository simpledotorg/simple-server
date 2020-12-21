require "rails_helper"

RSpec.describe Csv::FacilitiesParser do
  describe ".parse" do
    context "when regions_prep is disabled" do
      let(:upload_file) { fixture_file_upload("files/upload_facilities_test.csv", "text/csv") }

      it "parses the facilities" do
        facilities = described_class.parse(upload_file)

        expect(facilities.first).to have_attributes(organization_name: "OrgOne",
                                                    facility_group_name: "FGTwo",
                                                    name: "Test Facility",
                                                    facility_type: "CHC",
                                                    district: "Bhatinda",
                                                    state: "Punjab",
                                                    country: "India",
                                                    facility_size: "community",
                                                    enable_diabetes_management: true)

        expect(facilities.second).to have_attributes(organization_name: "OrgOne",
                                                     facility_group_name: "FGTwo",
                                                     name: "Test Facility 2",
                                                     facility_type: "CHC",
                                                     district: "Bhatinda",
                                                     state: "Punjab",
                                                     facility_size: "large",
                                                     country: "India")
      end

      it "defaults enable_diabetes_management to false if blank" do
        facilities = described_class.parse(upload_file)

        expect(facilities.second.enable_diabetes_management).to be false
      end
    end

    context "when regions_prep is enabled" do
      let(:upload_file) { fixture_file_upload("files/upload_facilities_without_state_test.csv", "text/csv") }

      before do
        enable_flag(:regions_prep)
      end

      it "sets the state" do
        create(:facility_group, name: "FGTwo", state: "Maharashtra", organization: create(:organization, name: "OrgOne"))

        facilities = described_class.parse(upload_file)

        expect(facilities.first).to have_attributes(organization_name: "OrgOne", facility_group_name: "FGTwo", state: "Maharashtra")
      end
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
