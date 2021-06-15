require "rails_helper"

describe ImoApiService, type: :model do
  describe "#invite" do
    let(:service) { ImoApiService.new(phone_number: "555-555-5555", message: "You are invited", recipient_name: "Theodore Logan") }
    let(:request_url) { "https://sgp.imo.im/api/simple/send_invite" }
    let(:auth_token) { Base64.strict_encode64(["add_username_to_env", "add_password_to_env"].join(":")) }
    let(:request_headers) do
      {
        "Authorization" => "Basic #{auth_token}",
        "Connection" => "close",
        "Host" => "sgp.imo.im",
        "User-Agent" => "http.rb/4.4.1"
      }
    end

    it "handles error" do
      stub_request(:post, request_url).to_timeout

      expect {
        service.invite
      }.to raise_error(ImoApiService::HTTPError)
    end

    it "returns nonxistent_user when status if 400 and type is nonexistent_user" do
      body = JSON(
        "status" => "error",
        "response" => {
            "message" => "No user with specified phone number",
            "type" => "nonexistent_user"
        }
      )
      stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: body)
      expect(service.invite).to eq("nonexistent_user")
    end

    # this needs to be changed to test object creation
    it "returns success" do
      stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200)
      expect(service.invite).to eq("success")
    end
  end
end