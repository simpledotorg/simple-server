require "rails_helper"

describe ExotelAPIService, type: :model do
  let(:account_sid) { Faker::Internet.user_name }
  let(:token) { SecureRandom.base64 }
  let(:service) { ExotelAPIService.new(account_sid, token) }
  let(:auth_token) { Base64.strict_encode64([account_sid, token].join(":")) }
  let(:request_headers) do
    {
      "Authorization" => "Basic #{auth_token}",
      "Connection" => "close",
      "Host" => "api.exotel.com",
      "User-Agent" => "http.rb/#{HTTP::VERSION}"
    }
  end

  around do |example|
    WebMock.disallow_net_connect!
    Flipper.enable(:exotel_whitelist_api)
    example.run
    Flipper.disable(:exotel_whitelist_api)
    WebMock.allow_net_connect!
  end

  describe "#call_details" do
    let!(:call_details_200) { File.read("spec/support/fixtures/call_details_200.json") }
    let!(:call_details_400) { File.read("spec/support/fixtures/call_details_400.json") }
    let!(:sid) { JSON(call_details_200).dig("Call", "AccountSid") }
    let!(:call_sid) { JSON(call_details_200).dig("Call", "Sid") }
    let!(:token) { "token" }
    let!(:auth_token) { Base64.strict_encode64([sid, token].join(":")) }
    let!(:request_url) { "https://api.exotel.com/v1/Accounts/sid/Calls/#{call_sid}.json" }
    let!(:request_headers) do
      {
        "Authorization" => "Basic #{auth_token}",
        "Connection" => "close",
        "Host" => "api.exotel.com",
        "User-Agent" => "http.rb/#{HTTP::VERSION}"
      }
    end

    it "should return call details for a session id in json when status is 200" do
      stub_request(:get, request_url).with(headers: request_headers).to_return(status: 200,
                                                                               body: call_details_200,
                                                                               headers: {})
      response = described_class.new(sid, token).call_details(call_sid)

      expect(response[:Call][:From]).to eq("09663127355")
      expect(response[:Call][:To]).to eq("01930483621")
      expect(response[:Call].keys).to eq(%i[Sid
        ParentCallSid
        DateCreated
        DateUpdated
        AccountSid
        To
        From
        PhoneNumberSid
        Status
        StartTime
        EndTime
        Duration
        Price
        Direction
        AnsweredBy
        ForwardedFrom
        CallerName
        Uri
        RecordingUrl])
    end

    it "should not return a response for a session that does not exist" do
      stub_request(:get, request_url).with(headers: request_headers).to_return(status: 400,
                                                                               body: call_details_400,
                                                                               headers: {})

      expected_call_details_response = described_class.new(sid, token).call_details(call_sid)

      expect(expected_call_details_response).to eq(nil)
    end

    it "should not return a response when the api returns a 500" do
      stub_request(:get, request_url).with(headers: request_headers).to_return(status: 500,
                                                                               headers: {})

      expected_call_details_response = described_class.new(sid, token).call_details(call_sid)

      expect(expected_call_details_response).to eq(nil)
    end

    it "should report an error if there is a network timeout while calling the api" do
      stub_request(:get, request_url).to_timeout

      expect(Sentry).to receive(:capture_message).and_return(true)

      expect {
        described_class.new(sid, token).call_details(call_sid)
      }.to raise_error(ExotelAPIService::HTTPError)
    end
  end

  describe "#whitelist_phone_numbers" do
    let(:request_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/CustomerWhitelist.json") }
    let(:virtual_number) { Faker::PhoneNumber.phone_number }
    let(:phone_numbers) { (0..3).map { Faker::PhoneNumber.phone_number } }
    let!(:auth_token) { Base64.strict_encode64([account_sid, token].join(":")) }

    let(:request_body) do
      {
        Language: "en",
        VirtualNumber: virtual_number,
        Number: phone_numbers.join(",")
      }
    end

    it "calls the exotel whitelist api for given virtual number and phone number list" do
      stub = stub_request(:post, request_url).with(
        headers: request_headers,
        body: request_body
      )

      service.whitelist_phone_numbers(virtual_number, phone_numbers)
      expect(stub).to have_been_requested
    end
  end

  describe "parse_exotel_whitelist_expiry" do
    it "returns nil if expiry time is nil" do
      expect(service.parse_exotel_whitelist_expiry(nil)).to be_nil
    end

    it "returns nil if expiry time is less than 0" do
      expect(service.parse_exotel_whitelist_expiry(-1)).to be_nil
    end

    it "return the time at which the expiry will happen if expiry time is greater than 0" do
      Timecop.freeze(Time.current) do
        expected_time = 1.hour.from_now
        expect(service.parse_exotel_whitelist_expiry(3600)).to eq(expected_time)
      end
    end
  end

  describe "get_phone_number_details" do
    let(:phone_number) { Faker::PhoneNumber.phone_number }
    let(:whitelist_details_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/CustomerWhitelist/#{ERB::Util.url_encode(phone_number)}.json") }
    let(:numbers_metadata_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/Numbers/#{ERB::Util.url_encode(phone_number)}.json") }

    let!(:whitelist_details_stub) do
      stub_request(:get, whitelist_details_url).with(headers: request_headers)
        .to_return(
          status: 200,
          headers: {},
          body: JSON(
            "Result" =>
               {"Status" => "Whitelist",
                "Type" => "API",
                "Expiry" => 3600}
          )
        )
    end
    let!(:numbers_metadata_stub) do
      stub_request(:get, numbers_metadata_url).with(headers: request_headers)
        .to_return(
          status: 200,
          headers: {},
          body: JSON(
            "Numbers" =>
               {"PhoneNumber" => phone_number,
                "Circle" => "KA",
                "CircleName" => "Karnataka",
                "Type" => "Mobile",
                "Operator" => "V",
                "OperatorName" => "Vodafone",
                "DND" => "Yes"}
          )
        )
    end

    it "makes a request to exotel number metadata and whitelist details api" do
      service.phone_number_details(phone_number)
      expect(numbers_metadata_stub).to have_been_requested
      expect(whitelist_details_stub).to have_been_requested
    end

    it "returns the phone number status returned from the two apis" do
      Timecop.freeze do
        expect(service.phone_number_details(phone_number))
          .to eq(dnd_status: true,
                 phone_type: :mobile,
                 whitelist_status: :whitelist,
                 whitelist_status_valid_until: Time.current + 3600.seconds)
      end
    end
  end
end
