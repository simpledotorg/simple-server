require 'rails_helper'

RSpec.describe MasterUser, type: :model do
  describe 'Associations' do
    it { should have_many(:master_user_authentications) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:full_name) }
  end

  describe 'Behavior' do
  end
end
