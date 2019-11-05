require 'rails_helper'

RSpec.describe User, type: :model do
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
          device_created_at: Time.current.iso8601,
          device_updated_at: Time.current.iso8601
        }
      end

      let(:user) { User.build_with_phone_number_authentication(params) }
      let(:phone_number_authentication) { user.phone_number_authentication }

      it 'builds a valid user' do
        expect(user).to be_valid
        expect(user.id).to eq(id)
        expect(user.full_name).to eq(full_name)
        expect(user.user_authentications).to be_present
        expect(user.user_authentications.size).to eq(1)
      end

      it 'builds a valid phone number authentication a user' do
        expect(phone_number_authentication).to be_instance_of(PhoneNumberAuthentication)
        expect(phone_number_authentication).to be_valid
        expect(phone_number_authentication.password_digest).to eq(password_digest)
        expect(phone_number_authentication.registration_facility_id).to eq(registration_facility.id)
      end

      it 'assigns an otp and access token to the phone number authentication' do
        expect(phone_number_authentication.otp).to be_present
        expect(phone_number_authentication.otp_valid_until).to be_present
        expect(phone_number_authentication.access_token).to be_present
      end

      it 'creates the user with required associations when save is called on it' do
        expect { user.save }.to change(User, :count).by(1)

        expect(user.user_authentications).to be_present
        expect(user.phone_number_authentication).to be_present
        expect(user.phone_number_authentication)
          .to eq(PhoneNumberAuthentication.find_by(phone_number: phone_number))
      end
    end
  end

  xdescribe '.update_with_phone_number_authentication' do

  end
end
