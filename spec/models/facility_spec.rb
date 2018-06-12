require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe 'Associations' do
    it { should have_many(:blood_pressures) }
    it { should have_many(:prescription_drugs) }
    it { should have_many(:patients).through(:blood_pressures) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name)}
    it { should validate_presence_of(:district)}
    it { should validate_presence_of(:state)}
    it { should validate_presence_of(:country)}
  end
end
