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

      it "returns 'invited' on 200 success" do
        locale = "bn-BD"
        request_body = JSON(
          phone: patient.latest_mobile_number,
          msg: I18n.t("notifications.imo.invitation.request", patient_name: patient.full_name, locale: locale),
          contents: [
            {
              key: I18n.t("notifications.imo.section_headers.name", locale: locale),
              value: patient.full_name
            },
            {
              key: I18n.t("notifications.imo.section_headers.message", locale: locale),
              value: I18n.t("notifications.imo.invitation.request", patient_name: patient.full_name, locale: locale)
            }
          ],
          title: I18n.t("notifications.imo.invitation.title", locale: locale),
          action: I18n.t("notifications.imo.invitation.action", locale: locale),
          callback_url: "https://localhost/api/v3/patients/#{patient.id}/imo_authorization"
        )
        stub = stub_request(:post, request_url).with(headers: request_headers, body: request_body).to_return(status: 200, body: success_body)

        expect(service.send_invitation(patient)).to eq(:invited)
        expect(stub).to have_been_requested
      end

      it "returns 'invited' when patient is already invited" do
        already_invited = JSON(
          status: "success",
          response: {
            error_code: "invited"
          }
        )
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: already_invited)

        expect(service.send_invitation(patient)).to eq(:invited)
      end

      it "returns 'subscribed' when patient is already subscribed'" do
        already_subscribed = JSON(
          status: "success",
          response: {
            error_code: "subscribed"
          }
        )
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: already_subscribed)

        expect(service.send_invitation(patient)).to eq(:subscribed)
      end

      it "raises an error on any other 200 response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: {}.to_json)
        expect {
          service.send_invitation(patient)
        }.to raise_error(ImoApiService::Error)
      end

      it "returns 'no_imo_account' on 400 when response type is nonexistent_user" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: nonexistent_user_body)

        expect(service.send_invitation(patient)).to eq(:no_imo_account)
      end

      it "raises an error on any other 400 response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)

        expect {
          service.send_invitation(patient)
        }.to raise_error(ImoApiService::Error)
      end

      it "raises an error on any other response code" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 500, body: {}.to_json)

        expect {
          service.send_invitation(patient)
        }.to raise_error(ImoApiService::Error)
      end

      it "raises an error on network error" do
        stub_request(:post, request_url).to_timeout

        expect {
          service.send_invitation(patient)
        }.to raise_error(ImoApiService::Error)
      end

      it "raises an error when the patient's locale is not supported" do
        allow(patient).to receive(:locale).and_return("bn-IN")

        expect {
          service.send_invitation(patient)
        }.to raise_error(ImoApiService::Error)
      end

      it "overrides the patient's phone number with an optional phone number argument" do
        phone_number = "+9991112223333"
        locale = "bn-BD"
        request_body = JSON(
          phone: phone_number,
          msg: I18n.t("notifications.imo.invitation.request", patient_name: patient.full_name, locale: locale),
          contents: [
            {
              key: I18n.t("notifications.imo.section_headers.name", locale: locale),
              value: patient.full_name
            },
            {
              key: I18n.t("notifications.imo.section_headers.message", locale: locale),
              value: I18n.t("notifications.imo.invitation.request", patient_name: patient.full_name, locale: locale)
            }
          ],
          title: I18n.t("notifications.imo.invitation.title", locale: locale),
          action: I18n.t("notifications.imo.invitation.action", locale: locale),
          callback_url: "https://localhost/api/v3/patients/#{patient.id}/imo_authorization"
        )

        stub = stub_request(:post, request_url).with(headers: request_headers, body: request_body).to_return(status: 200, body: success_body)

        expect(service.send_invitation(patient, phone_number: phone_number)).to eq(:invited)
        expect(stub).to have_been_requested
      end
    end
  end

  describe "#send_notification" do
    let(:notification) { create(:notification, patient: patient) }
    let(:request_url) { "https://sgp.imo.im/api/simple/send_notification" }
    let(:phone_number) { "+9990001112222" }

    context "with feature flag off" do
      it "returns nil" do
        expect(service.send_notification(notification, phone_number)).to eq(nil)
      end
    end

    context "with feature flag on" do
      let(:imo_auth) { create(:imo_authorization, patient: patient, status: "invited") }
      before do
        Flipper.enable(:imo_messaging)
        imo_auth
      end

      it "returns 'sent' result and post_id on a successful 200 response" do
        response = JSON(
          response: {
            status: "success",
            result: {post_id: "find_me"}
          }
        )
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: response)
        expect(Sentry).not_to receive(:capture_message)
        expect(service.send_notification(notification, phone_number)).to eq({result: :sent, post_id: "find_me"})
      end

      it "handles no_imo_account response" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: nonexistent_user_body)
        expect(Sentry).not_to receive(:capture_message)
        expect(service.send_notification(notification, phone_number)).to eq({result: :no_imo_account, post_id: nil})
      end

      it "handles not_subscribed response" do
        response = JSON(
          status: "error",
          response: {
            error_code: "not_subscribed"
          }
        )
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: response)
        expect(Sentry).not_to receive(:capture_message)
        expect(service.send_notification(notification, phone_number)).to eq({result: :not_subscribed, post_id: nil})
      end

      it "raises an error on other 200 responses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 200, body: {}.to_json)

        expect {
          service.send_notification(notification, phone_number)
        }.to raise_error(ImoApiService::Error)
      end

      it "raises an error on other 400 responses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 400, body: {}.to_json)

        expect {
          service.send_notification(notification, phone_number)
        }.to raise_error(ImoApiService::Error)
      end

      it "raises an error on other statuses" do
        stub_request(:post, request_url).with(headers: request_headers).to_return(status: 401, body: {}.to_json)

        expect {
          service.send_notification(notification, phone_number)
        }.to raise_error(ImoApiService::Error)
      end

      it "raises an error on network error" do
        stub_request(:post, request_url).to_timeout

        expect {
          service.send_notification(notification, phone_number)
        }.to raise_error(ImoApiService::Error)
      end

      it "raises an error when the patient's locale is not supported" do
        allow(patient).to receive(:locale).and_return("bn-IN")

        expect {
          service.send_notification(notification, phone_number)
        }.to raise_error(ImoApiService::Error)
      end
    end
  end
end
