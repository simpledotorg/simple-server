require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Associations' do
    it { should belong_to(:facility) }
    it { should have_many(:blood_pressures) }
    it { should have_many(:patients).through(:blood_pressures) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number) }
    it { should validate_inclusion_of(:sync_approval_status).in_array(User::STATUSES) }
  end
end
