require 'rails_helper'

RSpec.describe UserPermission, type: :model do
  describe 'Associations' do
    it { should belong_to(:master_user) }
    it { should belong_to(:resource).polymorphic(true) }
  end
end
