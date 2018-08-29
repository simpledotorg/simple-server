require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe 'Associations' do
    it { should have_many(:users) }
    it { should have_many(:blood_pressures) }
    it { should have_many(:prescription_drugs) }
    it { should have_many(:patients).through(:blood_pressures) }
    it { should have_many(:appointments) }
    it 'deletes all dependent user facilities' do
      facility = FactoryBot.create(:facility)
      FactoryBot.create_list(:user_facility, 5, facility: facility)
      expect { facility.destroy }.to change { UserFacility.count }.by(-5)
    end
  end

  describe 'Validations' do
    it { should validate_presence_of(:name)}
    it { should validate_presence_of(:district)}
    it { should validate_presence_of(:state)}
    it { should validate_presence_of(:country)}
    it { should validate_numericality_of(:pin)}
  end
end
