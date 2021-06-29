require "rails_helper"

describe ImoApiService, type: :model do
  let(:patient) { create(:patient) }
  let(:service) { ImoApiService.new(patient) }

  describe "#invite" do
    let(:request_url) { "https://sgp.imo.im/api/simple/send_invite" }
    let(:auth_token) { Base64.strict_encode64([nil, nil].join(":")) }
    let(:request_headers) do
      {
        "Authorization" => "Basic #{auth_token}",
        "Host" => "sgp.imo.im"
      }
    end

    context "with feature flag off" do
      it "returns nil" do
        expect(service.invite).to eq(nil)
      end
    end

    context "with feature flag on" do
      before { Flipper.enable(:imo_messaging) }

      it "returns :invited on 200" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200)
        expect(service.invite).to eq(:invited)
      end

      it "returns :no_imo_account when status if 400 and type is nonexistent_user" do
        body = JSON(
          "status" => "error",
          "response" => {
            "message" => "No user with specified phone number",
            "type" => "nonexistent_user"
          }
        )
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: body)
        expect(service.invite).to eq(:no_imo_account)
      end

      it "raises error on any other response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)

        expect {
          service.invite
        }.to raise_error(ImoApiService::Error)
      end

      it "raises a custom error on network error" do
        stub_request(:post, request_url).to_timeout

        expect {
          service.invite
        }.to raise_error(ImoApiService::Error)
      end
    end
  end

  describe "#send_notification" do
    let(:request_url) { "https://sgp.imo.im/api/simple/send_notification" }
    let(:auth_token) { Base64.strict_encode64([nil, nil].join(":")) }
    let(:request_headers) do
      {
        "Authorization" => "Basic #{auth_token}",
        "Host" => "sgp.imo.im"
      }
    end

    context "with feature flag off" do
      it "returns nil" do
        expect(service.send_notification("Come back in to the clinic")).to eq(nil)
      end
    end

    context "with feature flag on" do
      before { Flipper.enable(:imo_messaging) }

      it "returns :success on 200" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200)
        expect(service.send_notification("Come back in to the clinic"))
      end

      it "returns :failure when status is non-200" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400)
        expect(service.send_notification("Come back in to the clinic")).to eq(:failure)
      end
    end
  end
end
