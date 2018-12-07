require 'rails_helper'

RSpec.describe AdminAccessControl, type: :model do
  describe 'Associations' do
    it { should belong_to(:admin) }
    it { should belong_to(:facility_group) }
  end
  describe 'Validations' do
    it { should validate_presence_of(:admin) }
    it { should validate_presence_of(:facility_group) }
  end
end
