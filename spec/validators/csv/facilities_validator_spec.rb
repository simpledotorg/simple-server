require "rails_helper"

RSpec.describe Csv::FacilitiesValidator do
  describe "#validate" do
    context "when no facilities are passed in" do
      it "returns an error about no facilities" do
        validator = described_class.new([])
        expect(validator.validate.errors).to eq(["Uploaded file doesn't contain any valid facilities"])
      end
    end

    context "when there are duplicate rows" do
      it "returns an error message about duplicate facilities" do
        organization = create(:organization, name: "O")
        create(:facility_group, name: "FG", organization_id: organization.id)
        facilities = FactoryBot.create_list(:facility, 2, organization_name: "O", facility_group_name: "FG", name: "F")
          .map { |facility| {facility: facility, business_identifiers: []} }
        validator = described_class.new(facilities)

        validator.validate

        expect(validator.errors).to eq ["Uploaded file has duplicate facilities"]
      end
    end

    context "when there are duplicate business identifiers" do
      it "returns an error message about duplicate facilities" do
        organization = create(:organization, name: "O")
        create(:facility_group, name: "FG", organization_id: organization.id)
        facility = FactoryBot.create(:facility, organization_name: "O", facility_group_name: "FG", name: "F")
        business_identifier = create(:facility_business_identifier, identifier: "abc", facility_id: facility.id)
        validator = described_class.new([
          {facility: facility, business_identifiers: [business_identifier, business_identifier]}
        ])

        validator.validate

        expect(validator.errors).to eq ["Uploaded file has duplicate business identifiers"]
      end
    end

    context "when there are no duplicate identifiers" do
      it "does not return an error message about duplicate facilities" do
        organization = create(:organization, name: "O")
        create(:facility_group, name: "FG", organization_id: organization.id)
        facility = FactoryBot.create(:facility, organization_name: "O", facility_group_name: "FG", name: "F")
        business_identifier_1 = build_stubbed(:facility_business_identifier, identifier: "abc", facility_id: facility.id)
        business_identifier_2 = build_stubbed(:facility_business_identifier, identifier: "xyz", identifier_type: :external_org_facility_id, facility_id: facility.id)
        validator = described_class.new([
          {facility: facility, business_identifiers: [business_identifier_1, business_identifier_2]}
        ])

        validator.validate

        expect(validator.errors).to be_empty
      end
    end

    context "per-facility validations" do
      let(:organization) { create(:organization, name: "O") }
      let(:facility_group) { create(:facility_group, name: "FG", organization: organization) }
      let(:block) { create(:region, :block, name: "Zone 42", reparent_to: facility_group.region) }
      let(:facility) do
        build(:facility,
          organization_name: "O",
          facility_group_name: "FG",
          facility_group: facility_group,
          name: "facility",
          district: "district",
          state: "state",
          country: "country",
          block: block.name)
      end

      it "adds no errors when facility is valid" do
        facilities = [{facility: facility, business_identifiers: []}]
        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to eq []
      end

      it "adds an error when organization doesn't exist" do
        facility.assign_attributes(organization_name: "OrgTwo")
        facilities = [{facility: facility, business_identifiers: []}]
        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to eq ["Row(s) 2: Organization doesn't exist"]
      end

      it "adds an error when facility group doesn't exist" do
        facility.assign_attributes(facility_group_name: "FGTwo")
        facilities = [{facility: facility, business_identifiers: []}]
        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to eq ["Row(s) 2: Facility group doesn't exist for the organization"]
      end

      it "adds an error when attributes are invalid" do
        valid_params = {
          district: "district",
          enable_teleconsultation: false,
          facility_group_name: "FG",
          facility_group: facility_group,
          organization_name: "O",
          state: "state",
          zone: block.name
        }

        facilities = [
          {facility: build(:facility, valid_params.merge(district: nil, state: "state")), business_identifiers: []},
          {facility: build(:facility, valid_params.merge(district: "district", state: nil)), business_identifiers: []},
          {facility: build(:facility, valid_params.merge(country: nil)), business_identifiers: []},
          {facility: build(:facility, valid_params.merge(facility_size: "invalid size")), business_identifiers: []},
          {facility: build(:facility, valid_params.merge(enable_diabetes_management: nil, organization_name: nil)), business_identifiers: []},
          {facility: build(:facility, valid_params.merge(zone: "Invalid Zone")), business_identifiers: []}
        ]

        validator = described_class.new(facilities)
        validator.validate

        expect(validator.errors).to match_array [
          "Row(s) 2: District can't be blank",
          "Row(s) 3: State can't be blank",
          "Row(s) 4: Country can't be blank",
          "Row(s) 5: Facility size not in #{Facility.facility_sizes.values.join(", ")}",
          "Row(s) 6: Enable diabetes management is not included in the list",
          "Row(s) 6: Organization name can't be blank",
          "Row(s) 7: Zone not present in the facility group"
        ]
      end
    end
  end
end
