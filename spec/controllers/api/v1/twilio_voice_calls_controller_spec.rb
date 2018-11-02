require 'rails_helper'

RSpec.describe Api::V1::TwilioVoiceCallsController, type: :controller do
  before :each do
    twilio_username = ENV['TWILIO_CALLBACK_USERNAME']
    twilio_password = ENV['TWILIO_CALLBACK_PASSWORD']
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(twilio_username, twilio_password)
  end

  describe '#initiate' do
    it_behaves_like 'a controller that requires basic http authentication', :initiate
    it_behaves_like 'a controller that instructs to hangup if incoming number is unknown', :initiate

    describe 'Callback is received with calling phone number' do
      describe 'Calling number belongs to a known user' do
        let(:user) { FactoryBot.create(:user) }
        it 'should respond with instructions to gather patient phone number' do
          post :initiate, params: { 'From' => user.phone_number }

          response_body = Hash.from_xml(response.body)
          expect(response_body['Response'])
            .to eq({ 'Gather' => {
              'action' => 'http://test.host/api/v1/voice/twilio/connect',
              'finishOnKey' => '#',
              'method' => 'POST' } })
        end
      end
    end
  end

  describe '#connect' do
    it_behaves_like 'a controller that requires basic http authentication', :connect
    it_behaves_like 'a controller that instructs to hangup if incoming number is unknown', :connect

    describe 'Callback is received with calling phone number' do
      describe 'Calling number belongs to a known user' do
        let(:user) { FactoryBot.create(:user) }
        let(:patient_phone_number) { Faker::PhoneNumber.phone_number }
        it 'should respond with instructions to gather patient phone number' do
          post :connect, params: { 'From' => user.phone_number, 'Digits' => patient_phone_number }

          response_body = Hash.from_xml(response.body)
          expect(response_body['Response'])
            .to eq({ 'Dial' => patient_phone_number })
        end
      end
    end
  end
end
