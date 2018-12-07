require 'rails_helper'

describe Communication, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:appointment) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end
end
