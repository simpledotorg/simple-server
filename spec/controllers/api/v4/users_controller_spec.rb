require 'rails_helper'

RSpec.describe Api::V4::UsersController, type: :controller do
  describe '#activate' do
    let!(:user) { create(:user, password: '1234') }
    let!(:sms_notification_service) { double(SmsNotificationService.new(nil, nil)) }

    before do
      allow(Api::V4::UserTransformer).to receive(:to_response)
        .with(user)
        .and_return({ expected: 'response' }.as_json)


      allow(SmsNotificationService).to receive(:new).and_return(sms_notification_service)
      allow(sms_notification_service).to receive(:send_request_otp_sms).and_return(true)
    end

    it 'authenticates a registered user with the correct password, returns the users info, and sends a new OTP as an SMS' do
      existing_otp = user.otp
      expect(SmsNotificationService).to receive(:new).and_return(sms_notification_service)
      expect(sms_notification_service).to receive(:send_request_otp_sms).and_return(true)

      post :activate, params: { user: {id: user.id, password: '1234'} }

      expect(response.status).to eq(200)
      expect(JSON(response.body).with_int_timestamps).to eq({ expected: 'response' }.as_json)

      user.reload
      expect(user.otp).not_to eq(existing_otp)
    end

    it "doesn't authenticate a registered user with the wrong password, returns a 401" do
      existing_otp = user.otp

      expect(SmsNotificationService).not_to receive(:new)
      expect(sms_notification_service).not_to receive(:send_request_otp_sms)

      post :activate, params: { user: {id: user.id, password: '1235'} }

      expect(response.status).to eq(401)
      expect(JSON(response.body)).to eq('errors' => { 'user' => [I18n.t('login.error_messages.invalid_password')] })

      user.reload
      expect(user.otp).to eq(existing_otp)
    end

    it 'returns 404 when user is not found' do
      post :activate, params: { user: { id: SecureRandom.uuid, password: '1234' } }
      expect(response.status).to eq(404)
    end
  end
end
