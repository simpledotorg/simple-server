require "rails_helper"

RSpec.describe "Voice call outcomes API", type: :request do
  let(:detail) { create(:voice_call_detail, :with_communication) }
  let(:appointment) { detail.appointment }
  let(:machine_user) { create(:machine_user) }
  let(:application) { create(:oauth_application, owner: machine_user, scopes: "voice_agent") }
  let(:scopes) { "voice_agent" }
  let(:token) { create(:oauth_access_token, application: application, scopes: scopes, resource_owner_id: machine_user.id) }
  let(:headers) do
    {"ACCEPT" => "application/json",
     "CONTENT_TYPE" => "application/json",
     "HTTP_AUTHORIZATION" => "Bearer #{token.token}"}
  end
  let(:route) { "/api/v4/voice_call_outcomes" }
  let(:payload) do
    {
      call_request_id: detail.call_request_id,
      status: "completed",
      outcome: "agreed_to_visit",
      suggested_remove_reason: nil,
      safety_flag: false,
      confidence: "high",
      attempts: 2,
      answered_attempts: 1,
      last_attempted_at: "2026-09-15T11:32:10+06:00",
      connected_seconds: 118,
      provider: "twilio",
      prompt_version: "bd-overdue-v3"
    }
  end

  it "applies the outcome and returns 200" do
    post route, params: payload.to_json, headers: headers

    expect(response.status).to eq(200)
    expect(detail.reload).to be_status_completed
    expect(appointment.reload.agreed_to_visit).to eq(true)
  end

  it "accepts a payload without the optional prompt_version" do
    post route, params: payload.except(:prompt_version).to_json, headers: headers

    expect(response.status).to eq(200)
  end

  it "returns 200 and ignores a duplicate delivery" do
    post route, params: payload.to_json, headers: headers
    post route, params: payload.merge(outcome: "remind_to_call_later").to_json, headers: headers

    expect(response.status).to eq(200)
    expect(detail.reload.outcome).to eq("agreed_to_visit")
    expect(appointment.call_results.count).to eq(1)
  end

  it "returns 404 for an unknown call_request_id" do
    post route, params: payload.merge(call_request_id: SecureRandom.uuid).to_json, headers: headers

    expect(response.status).to eq(404)
  end

  it "returns 422 with errors for an invalid payload" do
    post route, params: payload.merge(status: "ringing").to_json, headers: headers

    expect(response.status).to eq(422)
    expect(JSON.parse(response.body)["errors"]).to have_key("status")
    expect(detail.reload).to be_status_requested
  end

  it "returns 401 without a token" do
    post route, params: payload.to_json, headers: headers.except("HTTP_AUTHORIZATION")

    expect(response.status).to eq(401)
  end

  context "with a token missing the voice_agent scope" do
    let(:application) { create(:oauth_application, owner: machine_user) }
    let(:scopes) { "write" }

    it "returns 403" do
      post route, params: payload.to_json, headers: headers

      expect(response.status).to eq(403)
      expect(detail.reload).to be_status_requested
    end
  end
end
