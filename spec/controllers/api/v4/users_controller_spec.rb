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

      post :activate, params: { user: { id: user.id, password: '1234' } }

      expect(response.status).to eq(200)
      expect(JSON(response.body).with_int_timestamps).to eq('user' => { expected: 'response' }.as_json)

      user.reload
      expect(user.otp).not_to eq(existing_otp)
    end

    it "doesn't authenticate a registered user with the wrong password, returns a 401" do
      existing_otp = user.otp

      expect(SmsNotificationService).not_to receive(:new)
      expect(sms_notification_service).not_to receive(:send_request_otp_sms)

      post :activate, params: { user: { id: user.id, password: '1235' } }

      expect(response.status).to eq(401)
      expect(JSON(response.body)).to eq('errors' => { 'user' => [I18n.t('login.error_messages.invalid_password')] })

      user.reload
      expect(user.otp).to eq(existing_otp)
    end

    it 'returns 401 when user is not found' do
      post :activate, params: { user: { id: 'random uuid', password: '1234' } }
      expect(response.status).to eq(401)
      expect(JSON(response.body)).to eq('errors' => { 'user' => [I18n.t('login.error_messages.invalid_password')] })
    end
  end

  describe '#me' do
    let(:facility_group) { create(:facility_group) }
    let(:facility) { create(:facility, facility_group: facility_group) }
    let(:user) { create(:user, registration_facility: facility, organization: facility.organization) }

    before(:each) do
      request.env['HTTP_X_USER_ID'] = user.id
      request.env['HTTP_X_FACILITY_ID'] = facility.id
      request.env['HTTP_AUTHORIZATION'] = "Bearer #{user.access_token}"

      allow(Api::V4::UserTransformer).to receive(:to_response)
        .with(user)
        .and_return({ expected: 'response' }.as_json)
    end

    it 'Returns the user information payload for a registered and authenticated user' do
      get :me
      expect(response.status).to eq(200)
      expect(JSON(response.body)).to eq('user' => { expected: 'response' }.as_json)
    end

    it 'Returns 401 if the user is not authenticated' do
      request.env['HTTP_AUTHORIZATION'] = 'an invalid access token'
      get :me, params: { id: user.id }
      expect(response.status).to eq(401)
    end

    it 'Returns 401 if the user is not present' do
      request.env['HTTP_X_USER_ID'] = 'random uuid'
      get :me, params: { id: 'random uuid' }
      expect(response.status).to eq(401)
    end
  end
end
