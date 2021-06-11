require "rails_helper"

describe ImoApiService, type: :model do
  describe "#invite" do
    let(:service) { ImoApiService.new(phone_number: "555-555-5555", message: "You are invited", recipient_name: "Theodore Logan") }
    let(:request_url) { "https://sgp.imo.im/api/simple/invite" }
    let(:request_headers) do
      {
        "Authorization" => 'Basic add_username_to_env:add_password_to_env',
        "Connection" => "close",
        "Host" => "sgp.imo.im",
        "User-Agent" => "http.rb/4.4.1"
      }
    end

    it "handles error" do

    end

    it "logs non-200 responses"

    it "does not raise an error on 200 response" do
      stub_request(:get, request_url).with(headers: request_headers).to_return(status: 200)
      service.invite
    end
  end
end