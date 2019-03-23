require 'rails_helper'

describe ExotelAPI, type: :model do
  describe '#call_details' do
    let!(:call_details_200) { File.read('spec/support/fixtures/call_details_200.json') }
    let!(:call_details_400) { File.read('spec/support/fixtures/call_details_400.json') }
    let!(:sid) { JSON(call_details_200).dig('Call', 'AccountSid') }
    let!(:call_sid) { JSON(call_details_200).dig('Call', 'Sid') }
    let!(:token) { 'token' }
    let!(:auth_token) { Base64.strict_encode64([sid, token].join(':')) }
    let!(:request_url) { "https://api.exotel.com/v1/Accounts/sid/Calls/#{call_sid}.json" }
    let!(:request_headers) {
      {
        'Authorization' => "Basic #{auth_token}",
        'Connection' => 'close',
        'Host' => 'api.exotel.com',
        'User-Agent' => 'http.rb/4.1.1'
      }
    }

    it 'should return call details for a session id in json when status is 200' do
      stub_request(:get, request_url).with(headers: request_headers).to_return(status: 200,
                                                                               body: call_details_200,
                                                                               headers: {})

      expected_call_details_response = described_class.new(sid, token).call_details(call_sid)

      expect(expected_call_details_response.Call.to_h.keys).to eq([:Sid,
                                                                   :ParentCallSid,
                                                                   :DateCreated,
                                                                   :DateUpdated,
                                                                   :AccountSid,
                                                                   :To,
                                                                   :From,
                                                                   :PhoneNumberSid,
                                                                   :Status,
                                                                   :StartTime,
                                                                   :EndTime,
                                                                   :Duration,
                                                                   :Price,
                                                                   :Direction,
                                                                   :AnsweredBy,
                                                                   :ForwardedFrom,
                                                                   :CallerName,
                                                                   :Uri,
                                                                   :RecordingUrl])
    end

    it 'should not return a response for a session that does not exist' do
      stub_request(:get, request_url).with(headers: request_headers).to_return(status: 400,
                                                                               body: call_details_400,
                                                                               headers: {})

      expected_call_details_response = described_class.new(sid, token).call_details(call_sid)

      expect(expected_call_details_response).to eq(nil)
    end

    it 'should not return a response when the api returns a 500' do
      stub_request(:get, request_url).with(headers: request_headers).to_return(status: 500,
                                                                               headers: {})

      expected_call_details_response = described_class.new(sid, token).call_details(call_sid)

      expect(expected_call_details_response).to eq(nil)
    end

    it 'should report an error if there is a network timeout while calling the api' do
      stub_request(:get, request_url).to_timeout

      expect(Raven).to receive(:capture_message).and_return(true)

      expect {
        described_class.new(sid, token).call_details(call_sid)
      }.to raise_error(ExotelAPI::HTTPError)
    end
  end
end
