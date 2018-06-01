require 'rails_helper'

describe Patient, type: :model do
  describe 'Associations' do
    it { should belong_to(:address) }
    it { should have_many(:phone_numbers) }
    it { should have_many(:blood_pressures) }
  end

  describe 'Validations' do
    it_behaves_like 'application record'
  end
end