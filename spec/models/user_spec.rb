require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Associations' do
    it { should have_many(:user_facilities) }
    it { should have_many(:facilities).through(:user_facilities) }
    it { should have_many(:blood_pressures) }
    it { should have_many(:patients).through(:blood_pressures) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number) }
  end
end
