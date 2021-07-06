require "rails_helper"

describe ImoApiService, type: :model do
  let(:patient) { create(:patient) }
  let(:service) { ImoApiService.new(patient) }
  let(:auth_token) { Base64.strict_encode64([nil, nil].join(":")) }
  let(:request_headers) do
    {
      "Authorization" => "Basic #{auth_token}",
      "Host" => "sgp.imo.im"
    }
  end
  let(:success_body) {
    JSON(
      response: {
        status: "success"
      }
    )
  }
  let(:nonexistent_user_body) {
    JSON(
      status: "error",
      response: {
        type: "nonexistent_user"
      }
    )
  }

  describe "#invite" do
    let(:request_url) { "https://sgp.imo.im/api/simple/send_invite" }

    context "with feature flag off" do
      it "returns nil" do
        expect(service.invite).to eq(nil)
      end
    end

    context "with feature flag on" do
      before { Flipper.enable(:imo_messaging) }

      it "creates an ImoAuthorization on 200 success" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: success_body)
        expect { service.invite }.to change { patient.imo_authorization }.from(nil)
        expect(patient.imo_authorization.status).to eq("invited")
      end

      it "raises error on any other 200 response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: {}.to_json)

        expect {
          service.invite
        }.to raise_error(ImoApiService::Error).with_message("Unknown 200 error from Imo")
      end

      it "updates patient's ImoAuthorization when status is 400 and type is nonexistent_user" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: nonexistent_user_body)
        expect { service.invite }.to change { patient.imo_authorization }.from(nil)
        expect(patient.imo_authorization.status).to eq("no_imo_account")
      end

      it "raises error on any other 400 response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)

        expect {
          service.invite
        }.to raise_error(ImoApiService::Error).with_message("Unknown 400 error from Imo")
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

    context "with feature flag off" do
      it "returns nil" do
        expect(service.send_notification("Come back in to the clinic")).to eq(nil)
      end
    end

    context "with feature flag on" do
      let(:imo_auth) { create(:imo_authorization, patient: patient, status: "invited") }
      before do
        Flipper.enable(:imo_messaging)
        imo_auth
      end

      it "does not have errors when response is successful" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: success_body)
        service.send_notification("Come back in to the clinic")
      end

      it "raises an error on other 200 responses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: {}.to_json)
        expect { service.send_notification("Come back in to the clinic") }
          .to raise_error(ImoApiService::Error).with_message("Unknown 200 error from Imo")
      end

      it "updates patient's ImoAuthorization when imo user does not exist" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: nonexistent_user_body)
        expect {
          service.send_notification("Come back in to the clinic")
        }.to change { patient.imo_authorization.reload.status }.from("invited").to("no_imo_account")
      end

      it "updates patient's ImoAuthorization when imo user is not subscribed" do
        not_subscribed_body = JSON(
          status: "success",
          response: {
            status: "failed",
            error_code: "not_subscribed"
          }
        )

        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: not_subscribed_body)
        expect {
          service.send_notification("Come back in to the clinic")
        }.to change { patient.imo_authorization.reload.status }.from("invited").to("not_subscribed")
      end

      it "raises an error on other 400 responses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)
        expect { service.send_notification("Come back in to the clinic") }
          .to raise_error(ImoApiService::Error).with_message("Unknown 400 error from Imo")
      end

      it "raises an error on other statuses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 401, body: {}.to_json)
        expect { service.send_notification("Come back in to the clinic") }
          .to raise_error(ImoApiService::Error).with_message("Unknown response error from Imo")
      end

      it "raises a custom error on network error" do
        stub_request(:post, request_url).to_timeout

        expect {
          service.send_notification("hi")
        }.to raise_error(ImoApiService::Error)
      end
    end
  end
end
