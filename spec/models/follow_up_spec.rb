require 'rails_helper'

describe FollowUp, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:follow_up_schedule) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end
end
