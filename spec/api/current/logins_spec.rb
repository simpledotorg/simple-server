require 'swagger_helper'

describe 'Login Current API', swagger_doc: 'current/swagger.json' do
  let!(:db_user) { FactoryBot.create(:master_user, :with_phone_number_authentication, password: '1234') }

  path '/login' do
    post 'Login in valid user' do
      tags 'User Login'
      parameter name: :user, in: :body, schema: Api::Current::Schema.user_login_request

      response '200', 'user is logged in' do
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password:     '1234',
                    otp:          db_user.otp
          } }
        end

        schema Api::Current::Schema.user_login_success_response
        run_test!
      end

      response '401', 'user is not logged in with expired otp' do
        let(:db_user) do
          Timecop.freeze(Date.today - 30) { FactoryBot.create(:master_user, :with_phone_number_authentication, password: '1234') }
        end
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password: '1234',
                    otp: db_user.otp
          } }
        end

        schema Api::Current::Schema.error
        run_test!
      end

      response '401', 'user is not logged in with wrong password' do
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password:     'wrong_password',
                    otp:          db_user.otp
          } }
        end

        schema Api::Current::Schema.error
        run_test!
      end

      response '401', 'user is not logged in with otp' do
        let(:user) do
          { user: { phone_number: db_user.phone_number,
                    password:     'wrong_password',
                    otp:          db_user.otp
          } }
        end

        schema Api::Current::Schema.error
        run_test!
      end
    end
  end
end
