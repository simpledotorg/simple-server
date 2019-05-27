require 'rails_helper'

RSpec.describe MasterUser, type: :model do
  describe 'Associations' do
    it { should have_many(:user_authentications) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:full_name) }
    it_behaves_like 'a record that validates device timestamps'
  end

  describe '.build_with_phone_number_authentication' do
    context 'all required params are present and are valid' do
      let(:registration_facility) { create(:facility) }
      let(:id) { SecureRandom.uuid }
      let(:full_name) { Faker::Name.name }
      let(:phone_number) { Faker::PhoneNumber.phone_number }
      let(:password_digest) { BCrypt::Password.create("1234") }
      let(:params) do
        { id: id,
          full_name: full_name,
          phone_number: phone_number,
          password_digest: password_digest,
          registration_facility_id: registration_facility.id,
          created_at: Time.now.iso8601,
          updated_at: Time.now.iso8601
        }
      end

      let(:master_user) { MasterUser.build_with_phone_number_authentication(params) }

      it 'builds a valid master user' do
        expect(master_user).to be_valid
        expect(master_user.id).to eq(id)
        expect(master_user.full_name).to eq(full_name)
        expect(master_user.user_authentications).to be_present
        expect(master_user.user_authentications.size).to eq(1)
      end

      it 'builds a valid phone number authentication a master user' do
        phone_number_authentication = master_user.user_authentications.first.authenticatable
        expect(phone_number_authentication).to be_instance_of(PhoneNumberAuthentication)
        expect(phone_number_authentication).to be_valid
        expect(phone_number_authentication.password_digest).to eq(password_digest)
        expect(phone_number_authentication.registration_facility_id).to eq(registration_facility.id)
      end

      it 'assigns an otp and access token to the phone number authentication' do
        phone_number_authentication = master_user.user_authentications.first.authenticatable
        expect(phone_number_authentication.otp).to be_present
        expect(phone_number_authentication.otp_valid_until).to be_present
        expect(phone_number_authentication.access_token).to be_present
      end

      it 'creates the master_user with required associations when save is called on it' do
        expect { master_user.save }.to change(MasterUser, :count).by(1)

        expect(master_user.user_authentications).to be_present
        expect(master_user.phone_number_authentication).to be_present
        expect(master_user.phone_number_authentication).to eq(PhoneNumberAuthentication.find_by(phone_number: phone_number))
      end
    end
  end
end
