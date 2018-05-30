require 'rails_helper'

RSpec.describe PatientPhoneNumber, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end
end
