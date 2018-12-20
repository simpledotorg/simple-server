require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'Associations' do
    it { should have_many(:admin_access_controls) }
  end
  describe 'Validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:role) }

    it { should define_enum_for(:role).with([:owner, :supervisor, :analyst]) }
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end
end
