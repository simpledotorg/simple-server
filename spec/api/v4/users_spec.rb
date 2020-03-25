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
        let(:db_user) { FactoryBot.create(:user, password: '1234') }
        let(:user) do
          { user: { id: db_user.id,
                    password: '1234' } }
        end

        schema Api::V4::Schema.user_activate_response
        run_test!
      end

      response '401', 'user is not logged in with wrong password' do
        let(:db_user) { FactoryBot.create(:user) }
        let(:user) do
          { user: { id: db_user.id,
                    password: 'wrong_password' } }
        end

        schema Api::V4::Schema.error
        run_test!
      end

      response '200', 'user otp is reset and new otp is sent as an sms' do
        let(:db_user) { FactoryBot.create(:user, password: '1234') }
        let(:user) do
          { user: { id: db_user.id,
                    password: '1234' } }
        end

        run_test!
      end

      response '404', 'user is not found' do
        let(:user) { { id: SecureRandom.uuid } }

        run_test!
      end
    end
  end
end
