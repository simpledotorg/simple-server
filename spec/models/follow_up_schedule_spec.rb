require 'rails_helper'

describe FollowUpSchedule, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
    it { should belong_to(:user).with_foreign_key(:action_by_user_id) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end
end
