require 'swagger_helper'

describe 'Users Current API', swagger_doc: 'current/swagger.json' do
  let(:supervisor) { FactoryBot.create(:admin, :supervisor) }
  let(:organization_owner) { FactoryBot.create(:admin, :organization_owner) }
  let(:facility) { FactoryBot.create(:facility) }

  before :each do
    FactoryBot.create(:admin_access_control, admin: supervisor)
    FactoryBot.create(:admin_access_control, admin: organization_owner, access_controllable: facility.facility_group)
  end

  path '/users/find' do
    get 'Find a existing user' do
      tags 'User'
      parameter name: :phone_number, in: :query, type: :string
      parameter name: :id, in: :query, type: :string, description: 'User UUID'

      let(:known_phone_number) { Faker::PhoneNumber.phone_number }
      let!(:user) { FactoryBot.create(:user, phone_number: known_phone_number, registration_facility_id: facility.id) }
      let(:id) { user.id }

      response '200', 'user is found' do
        schema '$ref' => '#/definitions/user'
        let(:phone_number) { known_phone_number }
        let(:id) { user.id }
        run_test!
      end

      response '404', 'user is not found' do
        let(:phone_number) { Faker::PhoneNumber.phone_number }
        run_test!
      end
    end
  end

  path '/users/register' do
    post 'Register a new user' do
      tags 'User'
      parameter name: :user, in: :body, schema: { '$ref' => '#/definitions/user' }

      let(:phone_number) { Faker::PhoneNumber.phone_number }

      response '200', 'user is registered' do
        let(:user) do
          { user: FactoryBot.attributes_for(
            :user_created_on_device,
            registration_facility_id: facility.id).merge(created_at: Time.now, updated_at: Time.now)
          }
        end

        schema Api::Current::Schema.user_registration_response
        run_test!
      end

      response '400', 'returns bad request for invalid params' do
        let(:user) do
          { user: FactoryBot.attributes_for(:user, :created_on_device)
                    .merge(created_at: Time.now,
                           updated_at: Time.now,
                           registration_facility_id: facility.id, full_name: nil) }
        end
        run_test!
      end

      response '400', 'returns bad request if phone number already exists' do
        let(:used_phone_number) { Faker::PhoneNumber.phone_number }
        let!(:existing_user) { FactoryBot.create(:user, phone_number: used_phone_number) }
        let(:user) do
          { user: FactoryBot.attributes_for(:user, :created_on_device, phone_number: used_phone_number)
                    .merge(created_at: Time.now,
                           updated_at: Time.now,
                           registration_facility_id: facility.id) }
        end
        run_test!
      end

      response '404', 'returns not found if  facility id is not known' do
        let(:user) do
          { user: FactoryBot.attributes_for(:user, :created_on_device, phone_number: phone_number)
                    .merge(created_at: Time.now, updated_at: Time.now, registration_facility_id: SecureRandom.uuid) }
        end
        run_test!
      end
    end
  end

  path '/users/{id}/request_otp' do
    post 'Request OTP for login' do
      tags 'User'
      parameter name: :id, in: :path, description: 'User UUID', type: :string

      let!(:user) { FactoryBot.create(:user, registration_facility_id: facility.id) }

      before :each do
        sms_notification_service = double(SmsNotificationService.new(nil))
        allow(SmsNotificationService).to receive(:new).and_return(sms_notification_service)
        allow(sms_notification_service).to receive(:send_request_otp_sms).and_return(true)
      end

      response '200', 'user otp is reset and new otp is sent as an sms' do
        let(:id) { user.id }
        run_test!
      end

      response '404', 'user is not found' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end

  path '/users/me/reset_password' do
    parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
    parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid

    post 'Request for reset password' do
      tags 'User'
      security [basic: []]
      parameter name: :password_digest, in: :body, schema: Api::Current::Schema.user_reset_password_request
      let(:user) { FactoryBot.create(:user, registration_facility_id: facility.id) }
      let(:HTTP_X_USER_ID) { user.id }
      let(:HTTP_X_FACILITY_ID) { facility.id }
      let(:Authorization) { "Bearer #{user.access_token}" }
      let(:password_digest) { { password_digest: BCrypt::Password.create('1234') } }

      response '200', 'user password reset request is received' do
        schema Api::Current::Schema.user_registration_response
        run_test!
      end

      response '401', 'user is not unauthorized' do
        let(:Authorization) { "Bearer #{SecureRandom.hex(32)}" }
        run_test!
      end
    end
  end
end
