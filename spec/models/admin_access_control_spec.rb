require 'rails_helper'

RSpec.describe AdminAccessControl, type: :model do
  describe 'Associations' do
    it { should belong_to(:admin) }
    it { should belong_to(:access_controllable) }
  end
  describe 'Validations' do
    it { should validate_presence_of(:admin) }
  end
end
