require 'rails_helper'

RSpec.describe CallLog, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:patient_phone_number) }
  end
end
