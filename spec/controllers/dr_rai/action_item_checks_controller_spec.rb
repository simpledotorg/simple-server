require "rails_helper"

RSpec.describe DrRai::ActionItemChecksController, type: :controller do
  let(:task) { "Email the lead doctors about tomorrow's clinic" }
  let(:evaluate_url) { "https://ai-gateway.vercel.sh/v1/evaluate" }

  before do
    setup_district_with_facilities
    admin = FactoryBot.create(:admin, :power_user)
    sign_in admin.email_authentication
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("AI_GATEWAY_API_KEY").and_return("test-key")
  end

  describe "POST /create" do
    it "returns the actionable probability from Jev" do
      stub_request(:post, evaluate_url).to_return(
        status: 200,
        body: {answers: {actionable: {probability: 0.91}}}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      post :create, params: {body: task}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["probability"]).to eq(0.91)
      expect(WebMock).to have_requested(:post, evaluate_url).with { |request|
        payload = JSON.parse(request.body)
        request.headers["Authorization"] == "Bearer test-key" &&
          payload["model"] == "typesafe-ai/jev" &&
          payload["state"]["item"] == task &&
          payload["questions"]["actionable"]["type"] == "boolean" &&
          payload["questions"]["actionable"]["instructions"].include?("facility manager")
      }
    end

    it "returns an error when the API key is missing" do
      allow(ENV).to receive(:[]).with("AI_GATEWAY_API_KEY").and_return(nil)

      post :create, params: {body: task}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Couldn't check this task")
      expect(WebMock).not_to have_requested(:post, evaluate_url)
    end

    it "returns an error when Jev fails" do
      stub_request(:post, evaluate_url).to_return(status: 502, body: "bad gateway")

      post :create, params: {body: task}

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body["error"]).to eq("Couldn't check this task")
    end
  end
end
