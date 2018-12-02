require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'Associations' do
    it { should have_many(:facility_groups) }

    it 'deletes all dependent facility groups' do
      organization = FactoryBot.create(:organization)
      facility_groups = FactoryBot.create_list(:facility_group, 5, organization: organization)
      expect { organization.destroy }.to change { FacilityGroup.count }.by(-5)
      expect(FacilityGroup.where(id: facility_groups.map(&:id))).to be_empty
    end

    it 'nullifies facility_group_id in facilities of the organization' do
      organization = FactoryBot.create(:organization)
      facility_groups = FactoryBot.create_list(:facility_group, 5, organization: organization)
      facility_groups.each { |facility_group| FactoryBot.create_list(:facility, 5, facility_group: facility_group)}
      expect { organization.destroy }.not_to change { Facility.count }
      expect(Facility.where(facility_group: facility_groups)).to be_empty
    end
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }
  end
end
