require 'rails_helper'

RSpec.describe SyncNetwork, type: :model do
  describe 'Associations' do
    it { should belong_to(:organisation) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }
  end
end
