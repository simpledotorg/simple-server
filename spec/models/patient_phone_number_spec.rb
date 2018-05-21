require 'rails_helper'

describe PatientPhoneNumber, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:phone_number) }
  end
end