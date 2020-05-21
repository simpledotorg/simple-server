require 'rails_helper'

RSpec.describe Admin::CSV::FacilityValidator do

  describe '.validate' do
    it 'calls all the validation methods' do
      facilities = []
      validator = described_class.new(facilities)
      allow(described_class).to receive(:new).and_return(validator)

      expect(validator).to receive(:at_least_one_facility)
      expect(validator).to receive(:duplicate_rows)
      expect(validator).to receive(:facilities)

      described_class.validate(facilities)
    end
  end

  describe '#at_least_one_facility' do
    context 'with no facilities ' do
      let!(:validator) { described_class.new([]) }
      before { validator.at_least_one_facility }

      specify { expect(validator.errors).to eq ["Uploaded file doesn't contain any valid facilities"] }
    end
  end

  describe '#duplicate_rows' do
    context 'with duplicate rows' do
      let!(:facilities) do
        create_list(:facility, 2, organization_name: 'Org', facility_group_name: 'FG', name: 'Facility')
      end
      let!(:validator) { described_class.new(facilities) }
      before { validator.duplicate_rows }

      specify { expect(validator.errors).to eq ['Uploaded file has duplicate facilities'] }
    end
  end

  describe '#facilities' do
    let!(:organization) { create(:organization, name: 'OrgOne') }
    let!(:facility_group) { create(:facility_group, name: 'FG', organization_id: organization.id) }
    let(:facility) do
      { organization_name: 'OrgOne',
        facility_group_name: 'FG',
        name: 'facility',
        district: 'district',
        state: 'state',
        country: 'country',
        import: true }
    end

    it "adds no errors when facility is valid" do
      facilities = [facility]
      validator = described_class.new(facilities)
      validator.facilities

      expect(validator.errors).to eq []
    end

    it "adds an error when organization doesn't exist" do
      facilities = [facility.merge(organization_name: 'OrgTwo')]
      validator = described_class.new(facilities)
      validator.facilities

      expect(validator.errors).to eq ["Row(s) 2: Organization doesn't exist"]
    end

    it "adds an error when facility group doesn't exist" do
      facilities = [facility.merge(facility_group_name: 'FGTwo')]
      validator = described_class.new(facilities)
      validator.facilities

      expect(validator.errors).to eq ["Row(s) 2: Facility group doesn't exist for the organization"]
    end

    it 'adds an error when attributes are invalid' do
      facilities = [build(:facility, district: nil),
                    build(:facility, state: nil),
                    build(:facility, country: nil),
                    build(:facility, facility_size: "invalid size"),
                    build(:facility, enable_diabetes_management: nil),
                    build(:facility, enable_teleconsultation: nil)].map(&:attributes)
      validator = described_class.new(facilities)
      validator.facilities

      expect(validator.errors).to match_array ["Row(s) 2: District can't be blank",
                                               "Row(s) 3: State can't be blank",
                                               "Row(s) 4: Country can't be blank",
                                               "Row(s) 5: Facility size not in #{Facility::facility_sizes.values.join(', ')}",
                                               "Row(s) 6: Enable diabetes management is not included in the list",
                                               "Row(s) 7: Enable teleconsultation is not included in the list"]
    end
  end
end
