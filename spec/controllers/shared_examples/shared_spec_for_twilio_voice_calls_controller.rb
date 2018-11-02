require 'rails_helper'

RSpec.shared_examples 'a controller that instructs to hangup if incoming number is unknown' do |action|
  describe 'Calling number deos not belongs to a known user' do
    it 'should respond with instructions to gather patient phone number' do
      post action, params: { 'From' => Faker::PhoneNumber.phone_number }

      response_body = Hash.from_xml(response.body)
      expect(response_body['Response'])
        .to eq({ 'Say' =>"{\"message\":\"#{I18n.t('voice_call.unknown_user')}\",\"voice\":\"#{I18n.t('voice_call.twilio.voice')}\"}", 'Hangup' =>nil})
    end
  end
end

RSpec.shared_examples 'a controller that requires basic http authentication' do |action|
  describe 'Callback received with invalid credentials' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('invalid_username', 'invalid_password')
    end

    it 'should respond with instructions to gather patient phone number' do
      post action, params: { 'From' => Faker::PhoneNumber.phone_number }

      expect(response.status).to eq(401)
    end
  end
end