require 'rails_helper'

RSpec.describe MasterUserAuthentication, type: :model do
  describe 'Associations' do
    it { should belong_to(:master_user) }
    it { should belong_to(:authenticatable) }
  end

  describe 'Validations' do
    it { should validate_uniqueness_of(:authenticatable_id).scoped_to(:master_user_id, :authenticatable_type)}
  end

  describe 'Behavior' do
  end
end
