require "rails_helper"

RSpec.describe Csv::FacilitiesValidator do
  describe "#validate" do
    context "when no facilities are passed in" do
      let!(:validator) { described_class.new([]) }
      before { validator.validate }

      specify { expect(validator.errors).to eq ["Uploaded file doesn't contain any valid facilities"] }
    end

    context "when there are duplicate rows" do
      let!(:organization) { create(:organization, name: "O") }
      let!(:facility_group) { create(:facility_group, name: "FG", organization_id: organization.id) }
      let!(:facilities) { create_list(:facility, 2, organization_name: "O", facility_group_name: "FG", name: "F") }
      let!(:validator) { described_class.new(facilities) }
      before { validator.validate }

      specify { expect(validator.errors).to eq ["Uploaded file has duplicate facilities"] }
    end

    context "per-facility validations" do
      let!(:organization) { create(:organization, name: "O") }
      let!(:facility_group) { create(:facility_group, name: "FG", organization_id: organization.id) }
      let(:facility) do
        build(:facility,
          organization_name: "O",
          facility_group_name: "FG",
          name: "facility",
          district: "district",
          state: "state",
          country: "country",
          zone: "zone")
      end

      it "adds no errors when facility is valid" do
        facilities = [facility]
        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to eq []
      end

      it "adds an error when organization doesn't exist" do
        facility.assign_attributes(organization_name: "OrgTwo")
        facilities = [facility]
        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to eq ["Row(s) 2: Organization doesn't exist"]
      end

      it "adds an error when facility group doesn't exist" do
        facility.assign_attributes(facility_group_name: "FGTwo")
        facilities = [facility]
        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to eq ["Row(s) 2: Facility group doesn't exist for the organization"]
      end

      it "adds an error when attributes are invalid" do
        facilities = [
          build(:facility, organization_name: "O", facility_group_name: "FG", district: nil, enable_teleconsultation: false),
          build(:facility, organization_name: "O", facility_group_name: "FG", state: nil, enable_teleconsultation: false),
          build(:facility, organization_name: "O", facility_group_name: "FG", country: nil, enable_teleconsultation: false),
          build(:facility, organization_name: "O", facility_group_name: "FG", facility_size: "invalid size", enable_teleconsultation: false),
          build(:facility, organization_name: "O", facility_group_name: "FG", enable_diabetes_management: nil, enable_teleconsultation: false)
        ]

        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to match_array [
          "Row(s) 2: District can't be blank",
          "Row(s) 3: State can't be blank",
          "Row(s) 4: Country can't be blank",
          "Row(s) 5: Facility size not in #{Facility.facility_sizes.values.join(", ")}",
          "Row(s) 6: Enable diabetes management is not included in the list"
        ]
      end
    end
  end
end
