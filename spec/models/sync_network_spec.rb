require 'rails_helper'

RSpec.describe SyncNetwork, type: :model do
  describe 'Associations' do
    it { should belong_to(:organization) }
    it { should have_many(:facilities) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }
  end
end
