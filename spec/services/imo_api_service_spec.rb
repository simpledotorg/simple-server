require "rails_helper"

describe ImoApiService, type: :model do
  describe "#invite" do
    let(:service) { ImoApiService.new(phone_number: "555-555-5555", recipient_name: "Theodore Logan", locale: "bn-BD") }
    let(:request_url) { "https://sgp.imo.im/api/simple/send_invite" }
    let(:auth_token) { Base64.strict_encode64([nil, nil].join(":")) }
    let(:request_headers) do
      {
        "Authorization" => "Basic #{auth_token}",
        "Host" => "sgp.imo.im"
      }
    end

    it "returns 'invited' on 200" do
      stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200)
      expect(service.invite).to eq("invited")
    end

    it "returns 'no_imo_account' when status if 400 and type is nonexistent_user" do
      body = JSON(
        "status" => "error",
        "response" => {
          "message" => "No user with specified phone number",
          "type" => "nonexistent_user"
        }
      )
      stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: body)
      expect(service.invite).to eq("no_imo_account")
    end

    it "returns 'failure' and logs with any other response" do
      stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)

      expect(Sentry).to receive(:capture_message).and_return(true)
      expect(service.invite).to eq("failure")
    end

    it "raises custom error and logs on network error" do
      stub_request(:post, request_url).to_timeout

      expect(Sentry).to receive(:capture_message).and_return(true)
      expect {
        service.invite
      }.to raise_error(ImoApiService::HTTPError)
    end
  end
end
