require 'rails_helper'

RSpec.describe MasterUser, type: :model do
  describe 'Associations' do
    it { should have_many(:user_authentications) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:full_name) }
    it_behaves_like 'a record that validates device timestamps'
  end
end
