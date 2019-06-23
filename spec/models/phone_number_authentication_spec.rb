require 'rails_helper'

RSpec.describe PhoneNumberAuthentication, type: :model do
  describe 'Associations' do
    it { should have_one(:user_authentication) }
    it { should have_one(:master_user).through(:user_authentication) }
    it { should belong_to(:facility).with_foreign_key('registration_facility_id') }
  end

  describe 'Validations' do
    let(:master_user) { create(:master_user, :with_phone_number_authentication) }
    let(:registration_facility) { create(:facility) }
    let(:subject) { create(:phone_number_authentication, master_user: master_user, facility: registration_facility) }

    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number).ignoring_case_sensitivity }

    context 'presence of password' do
      it 'validates a PhoneNumberAuthentication with a password' do
        phone_number_authentication = build(:phone_number_authentication, password: '1234')
        expect(phone_number_authentication).to be_valid
      end

      it 'validates a PhoneNumberAuthentication with a password_digest' do
        phone_number_authentication = build(:phone_number_authentication, :with_password_digest)
        expect(phone_number_authentication).to be_valid
      end

      it 'invalidates a PhoneNumberAuthentication without a password or a password_digest' do
        phone_number_authentication = build(:phone_number_authentication, password: nil, password_digest: nil)
        expect(phone_number_authentication).to be_invalid
      end
    end
  end
end