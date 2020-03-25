require 'swagger_helper'

describe 'Users v4 API', swagger_doc: 'v4/swagger.json' do
  path '/users/activate' do
    post 'Authenticate user, request OTP, and get user information' do
      tags 'User'
      parameter name: :user, in: :body, schema: Api::V4::Schema.user_activate_request

      before :each do
        sms_notification_service = double(SmsNotificationService.new(nil, nil))
        allow(SmsNotificationService).to receive(:new).and_return(sms_notification_service)
        allow(sms_notification_service).to receive(:send_request_otp_sms).and_return(true)
      end

      response '200', 'user is authenticated' do
        let(:db_user) { create(:user, password: '1234') }
        let(:user) do
          { user: { id: db_user.id,
                    password: '1234' } }
        end

        schema Api::V4::Schema.user_activate_response
        run_test!
      end

      response '401', 'incorrect user id or password, authentication failed' do
        let(:db_user) { create(:user) }
        let(:user) do
          { user: { id: db_user.id,
                    password: 'wrong_password' } }
        end

        schema Api::V4::Schema.error
        run_test!
      end

      response '200', 'user otp is reset and new otp is sent as an sms' do
        let(:db_user) { create(:user, password: '1234') }
        let(:user) do
          { user: { id: db_user.id,
                    password: '1234' } }
        end

        run_test!
      end
    end
  end

  path '/users/me/' do
    parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid, required: true
    parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid, required: true

    get 'Fetch user information' do
      tags 'User'
      security [basic: []]
      let(:facility) { create(:facility) }
      let(:user) { create(:user, registration_facility: facility) }
      let(:HTTP_X_USER_ID) { user.id }
      let(:HTTP_X_FACILITY_ID) { facility.id }
      let(:Authorization) { "Bearer #{user.access_token}" }

      response '200', 'returns user information' do
        schema Api::V4::Schema.user_me_response
        run_test!
      end

      response '401', 'authentication failed' do
        let(:Authorization) { "Bearer 'random string'" }
        run_test!
      end
    end
  end
end
