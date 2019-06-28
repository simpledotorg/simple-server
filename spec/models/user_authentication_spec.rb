require 'rails_helper'

RSpec.describe UserAuthentication, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:authenticatable) }
  end

  describe 'Validations' do
    it { should validate_uniqueness_of(:authenticatable_id)
                  .scoped_to(:user_id, :authenticatable_type)
                  .case_insensitive }
  end
end
