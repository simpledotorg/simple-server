require 'rails_helper'

RSpec.describe Api::V1::LoginsController, type: :controller do
  describe '#login_user' do
    let(:password) { '1234' }
    let(:db_user) { FactoryBot.create(:user, password: password) }
    describe 'request with valid phone number, password and otp' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password:     password,
              otp:          db_user.otp
            }
        }
      end

      it 'should respond with access token for the user' do
        post :login_user, params: request_params

        expect(response.code).to eq('200')
        expect(JSON(response.body)['user']['id']).to eq(db_user.id)
        expect(JSON(response.body)['access_token']).to eq(db_user.access_token)
      end
    end

    describe 'request with valid phone number, password and otp, but otp is expired' do
      let(:db_user) do
        Timecop.freeze(Date.today - 3) { FactoryBot.create(:user, password: password) }
      end
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password:     password,
              otp:          db_user.otp
            }
        }
      end
      it 'should respond with http status 401' do
        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
            'user' => ['otp has expired']
          })
      end
    end

    describe 'request with valid phone number and password but otp mismatches' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password:     '1234',
              otp:          'wrong otp'
            }
        }
      end
      it 'should respond with http status 401' do
        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
            'user' => ['otp is not valid']
          })
      end
    end

    describe 'request with valid phone number and otp but password mismatches' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password:     'wrong password',
              otp:          db_user.otp
            }
        }
      end
      it 'should respond with http status 401' do
        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
            'user' => ['password is not valid']
          })
      end
    end

    describe 'request with invalid phone number' do
      let(:request_params) do
        { user:
            { phone_number: 'wrong phone number',
              password:     '1234',
              otp:          db_user.otp
            }
        }
      end
      it 'should respond with http status 401' do
        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
            'user' => ['user is not present']
          })
      end
    end
  end
end
