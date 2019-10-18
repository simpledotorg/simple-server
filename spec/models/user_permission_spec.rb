require 'rails_helper'

RSpec.describe UserPermission, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:resource) }
  end
end
