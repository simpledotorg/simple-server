require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'Associations' do
    it { should have_many(:sync_networks) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }
  end
end
