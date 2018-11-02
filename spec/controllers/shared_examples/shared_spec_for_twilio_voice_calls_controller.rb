require 'rails_helper'

RSpec.shared_examples 'a controller that instructs to hangup if incoming number is unknown' do
  describe 'Calling number deos not belongs to a known user' do
    it 'should respond with instructions to gather patient phone number' do
      post :initiate, params: { 'From' => Faker::PhoneNumber.phone_number }

      response_body = Hash.from_xml(response.body)
      expect(response_body['Response'])
        .to eq({ 'Say' =>"{\"message\":\"#{I18n.t('voice_call.unknown_user')}\",\"voice\":\"#{I18n.t('voice_call.twilio.voice')}\"}", 'Hangup' =>nil})
    end
  end
end