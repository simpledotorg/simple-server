require 'rails_helper'

RSpec.describe Api::V3::LoginsController, type: :controller do
  describe '#login_user' do
    let(:password) { '1234' }
    let(:user) { FactoryBot.create(:user, password: password) }

    describe "valid authentication" do
      let(:request_params) do
        { user:
            { phone_number: user.phone_number,
              password: password,
              otp: user.otp } }
      end

      it 'responds with access token for the user' do
        post :login_user, params: request_params

        user.reload
        expect(response.code).to eq('200')
        expect(JSON(response.body)['user']['id']).to eq(user.id)
        expect(JSON(response.body)['access_token']).to eq(user.access_token)
      end

      it 'updates the access token for the user' do
        old_access_token = user.access_token
        post :login_user, params: request_params

        user.reload
        new_access_token = user.access_token
        expect(new_access_token).not_to eq(old_access_token)
      end

      it 'expires otp after use' do
        post :login_user, params: request_params

        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body)).to eq('errors' => { 'user' => [I18n.t('login.error_messages.expired_otp')] })
      end
    end

    describe "failed authentication" do
      it "returns 401 and sends error message" do
        user = create(:user, password: '4304')
        post :login_user, params: { user:
          { phone_number: user.phone_number,
            password: 'bad',
            otp: user.otp
          }
        }
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
                   'user' => [I18n.t('login.error_messages.invalid_password')]
                 })
      end
    end

    describe 'audit logs for login' do
      it 'creates an audit log of the user login' do
        user = FactoryBot.create(:user, password: '4041')

        Timecop.freeze do
          expect(AuditLogger).to receive(:info).with({ user: user.id,
                                      auditable_type: 'User',
                                      auditable_id: user.id,
                                      action: 'login',
                                      time: Time.current }.to_json)

          post :login_user, params: { user:
            { phone_number: user.phone_number,
              password: '4041',
              otp: user.otp }
            }
        end
      end
    end
  end
end
