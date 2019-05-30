require 'rails_helper'

RSpec.describe Api::V1::LoginsController, type: :controller do
  describe '#login_user' do
    let(:password) { '1234' }
    let!(:db_user) { create(:user, password: password) }
    describe 'request with valid phone number, password and otp' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password: password,
              otp: db_user.otp
            }
        }
      end

      it 'should respond with access token for the user' do
        post :login_user, params: request_params

        db_user.reload
        expect(response.code).to eq('200')
        expect(JSON(response.body)['user']['id']).to eq(db_user.id)
        expect(JSON(response.body)['access_token']).to eq(db_user.access_token)
      end

      it 'should update the access token for the user' do
        old_access_token = db_user.access_token
        post :login_user, params: request_params

        db_user.reload
        new_access_token = db_user.access_token
        expect(new_access_token).not_to eq(old_access_token)
      end
    end

    describe 'request with valid phone number, password and otp, but otp is expired' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password: password,
              otp: db_user.otp
            }
        }
      end
      it 'should respond with http status 401' do
        Timecop.travel(Date.today + 3.days) do
          post :login_user, params: request_params
          expect(response.status).to eq(401)
          expect(JSON(response.body))
            .to eq('errors' => {
              'user' => [I18n.t('login.error_messages.expired_otp')]
            })
        end
      end
    end

    describe 'request with valid phone number and password but otp mismatches' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password: '1234',
              otp: 'wrong otp'
            }
        }
      end
      it 'should respond with http status 401' do
        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
            'user' => [I18n.t('login.error_messages.invalid_otp')]
          })
      end
    end

    describe 'request with valid phone number and otp but password mismatches' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password: 'wrong password',
              otp: db_user.otp
            }
        }
      end
      it 'should respond with http status 401' do
        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
            'user' => [I18n.t('login.error_messages.invalid_password')]
          })
      end
    end

    describe 'request with invalid phone number' do
      let(:request_params) do
        { user:
            { phone_number: 'wrong phone number',
              password: '1234',
              otp: db_user.otp
            }
        }
      end
      it 'should respond with http status 401' do
        post :login_user, params: request_params
        expect(response.status).to eq(401)
        expect(JSON(response.body))
          .to eq('errors' => {
            'user' => [I18n.t('login.error_messages.unknown_user')]
          })
      end
    end

    describe 'audit logs for login' do
      let(:request_params) do
        { user:
            { phone_number: db_user.phone_number,
              password: password,
              otp: db_user.otp
            }
        }
      end

      it 'creates an audit log of the user login' do
        post :login_user, params: request_params
        audit_log = AuditLog.where(user_id: db_user.id).first

        expect(audit_log.action).to eq('login')
        expect(audit_log.auditable_type).to eq('MasterUser')
        expect(audit_log.auditable_id).to eq(db_user.id)
      end
    end
  end
end
