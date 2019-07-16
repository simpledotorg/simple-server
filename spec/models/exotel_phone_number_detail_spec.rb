require 'rails_helper'

RSpec.describe ExotelPhoneNumberDetail, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient_phone_number) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:whitelist_status) }
  end
end
