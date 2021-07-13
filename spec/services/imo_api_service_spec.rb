require "rails_helper"

describe ImoApiService, type: :model do
  let(:facility) { create(:facility, country: "Bangladesh") }
  let(:patient) { create(:patient, assigned_facility: facility) }
  let(:service) { ImoApiService.new }
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

  describe "#send_invitation" do
    let(:request_url) { "https://sgp.imo.im/api/simple/send_invite" }

    context "with feature flag off" do
      it "returns nil" do
        expect(service.send_invitation(patient)).to eq(nil)
      end
    end

    context "with feature flag on" do
      before { Flipper.enable(:imo_messaging) }

      it "creates an ImoAuthorization on 200 success" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: success_body)

        expect { service.send_invitation(patient) }.to change { patient.imo_authorization }.from(nil)
        expect(patient.imo_authorization.status).to eq("invited")
      end

      it "creates an ImoAuthorization and reports to sentry on any other 200 response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: {}.to_json)

        expect(Sentry).to receive(:capture_message)
        expect { service.send_invitation(patient) }.to change { patient.imo_authorization }.from(nil)
        expect(patient.imo_authorization.status).to eq("error")
      end

      it "creates an ImoAuthorization when status is 400 and type is nonexistent_user" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: nonexistent_user_body)

        expect { service.send_invitation(patient) }.to change { patient.imo_authorization }.from(nil)
        expect(patient.imo_authorization.status).to eq("no_imo_account")
      end

      it "creates an ImoAuthorization reports to sentry on any other 400 response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)

        expect(Sentry).to receive(:capture_message)
        service.send_invitation(patient)
      end

      it "raises a custom error and does not create an ImoAuthorization on network error" do
        stub_request(:post, request_url).to_timeout

        expect {
          service.send_invitation(patient)
        }.to raise_error(ImoApiService::Error)
        expect(patient.imo_authorization).to be_nil
      end

      it "raises an error when the patient's locale is not supported" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: success_body)
        allow(patient).to receive(:locale).and_return("en")

        expect {
          service.send_invitation(patient)
        }.to raise_error(ImoApiService::Error)
      end
    end
  end

  describe "#send_notification" do
    let(:request_url) { "https://sgp.imo.im/api/simple/send_notification" }

    context "with feature flag off" do
      it "returns nil" do
        expect(service.send_notification(patient, "Come back in to the clinic")).to eq(nil)
      end
    end

    context "with feature flag on" do
      let(:imo_auth) { create(:imo_authorization, patient: patient, status: "invited") }
      before do
        Flipper.enable(:imo_messaging)
        imo_auth
      end

      it "returns success on a successful 200 response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: success_body)
        expect(Sentry).not_to receive(:capture_message)
        expect(service.send_notification(patient, "Come back in to the clinic")).to eq(:success)
      end

      it "reports to sentry and returns error on other 200 responses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: {}.to_json)
        expect(Sentry).to receive(:capture_message)
        expect(service.send_notification(patient, "Come back in to the clinic")).to eq(:error)
      end

      it "updates patient's ImoAuthorization and returns no_imo_account when imo user does not exist" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: nonexistent_user_body)
        expect {
          service.send_notification(patient, "Come back in to the clinic")
        }.to change { patient.imo_authorization.status }.from("invited").to("no_imo_account")
      end

      it "updates patient's ImoAuthorization and returns not_subscribed when imo user is not subscribed" do
        not_subscribed_body = JSON(
          status: "success",
          response: {
            status: "failed",
            error_code: "not_subscribed"
          }
        )

        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: not_subscribed_body)
        expect {
          service.send_notification(patient, "Come back in to the clinic")
        }.to change { patient.imo_authorization.status }.from("invited").to("not_subscribed")
      end

      it "reports to sentry and returns error on other 400 responses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)

        expect(Sentry).to receive(:capture_message)
        expect(service.send_notification(patient, "Come back in to the clinic")).to eq(:error)
      end

      it "reports to sentry and returns error on other statuses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 401, body: {}.to_json)

        expect(Sentry).to receive(:capture_message)
        expect(service.send_notification(patient, "Come back in to the clinic")).to eq(:error)
      end

      it "raises a custom error on network error" do
        stub_request(:post, request_url).to_timeout

        expect {
          service.send_notification(patient, "Come back in to the clinic")
        }.to raise_error(ImoApiService::Error)
      end
    end
  end
end
