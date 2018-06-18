require 'swagger_helper'

describe 'Login API' do

  path '/login' do
    post 'Login in valid user' do
      tags 'User Login'
      parameter name: :user, in: :body, schema: Api::V1::Schema.user_login_request

      response '200', 'user is logged in' do
        let(:db_user) { FactoryBot.create(:user, password: '1234') }
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password:     '1234',
                    otp:          db_user.otp
          } }
        end

        schema Api::V1::Schema.user_login_success_response
        run_test!
      end

      response '401', 'user is not logged in with expired otp' do
        let(:db_user) { FactoryBot.create(:user, password: '1234', otp_valid_until: Time.now) }
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password:     '1234',
                    otp:          db_user.otp
          } }
        end

        schema Api::V1::Schema.user_login_failure_response
        Timecop.travel(20.minutes.from_now) do
          run_test!
        end
      end

      response '401', 'user is not logged in with wrong password' do
        let(:db_user) { FactoryBot.create(:user) }
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password:     'wrong_password',
                    otp:          db_user.otp
          } }
        end

        schema Api::V1::Schema.user_login_failure_response
        run_test!
      end

      response '401', 'user is not logged in with otp' do
        let(:db_user) { FactoryBot.create(:user) }
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password:     'wrong_password',
                    otp:          db_user.otp
          } }
        end

        schema Api::V1::Schema.user_login_failure_response
        run_test!
      end
    end
  end
end