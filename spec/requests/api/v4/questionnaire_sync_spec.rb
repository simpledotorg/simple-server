require "rails_helper"

RSpec.describe "Questionnaires sync", type: :request do
  let(:sync_route) { "/api/v4/questionnaires/sync" }
  let(:request_user) { create(:user) }

  let(:auth_headers) do
    {"HTTP_X_USER_ID" => request_user.id,
     "HTTP_X_FACILITY_ID" => request_user.facility.id,
     "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}"}
  end
  let(:headers) do
    {"ACCEPT" => "application/json", "CONTENT_TYPE" => "application/json"}.merge(auth_headers)
  end

  let(:model) { Questionnaire }
  let(:response_key) { "questionnaires" }
  let(:dsl_version) { "1.2" }

  before do
    Questionnaire.questionnaire_types.values.each do |questionnaire_type|
      create(:questionnaire, :active, questionnaire_type: questionnaire_type, dsl_version: dsl_version)
    end
  end

  context "resync_token in request headers is present" do
    let(:resync_token) { "1" }
    let(:headers_with_resync_token) { headers.merge("HTTP_X_RESYNC_TOKEN" => resync_token) }
    let(:process_token_without_resync) do
      make_process_token(current_facility_processed_since: Time.current)
    end

    it "syncs all records from beginning if resync_token in process_token is nil" do
      get sync_route, params: {process_token: process_token_without_resync, dsl_version: dsl_version}, headers: headers_with_resync_token
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(3)
      expect(parse_process_token(response_body)[:resync_token]).to eq(resync_token)
    end

    it "syncs all records from beginning if resync_token in headers is different from the one in process_token" do
      get sync_route,
        params: {
          process_token: make_process_token(current_facility_processed_since: Time.current,
            resync_token: "2"),
          dsl_version: dsl_version
        },
        headers: headers_with_resync_token
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(3)
      expect(parse_process_token(response_body)[:resync_token]).to eq(resync_token)
    end

    it "syncs normally once resync_token has been calibrated" do
      get sync_route, params: {process_token: process_token_without_resync, dsl_version: dsl_version}, headers: headers_with_resync_token
      process_token_with_resync = JSON(response.body)["process_token"]

      get sync_route, params: {process_token: process_token_with_resync, dsl_version: dsl_version}, headers: headers_with_resync_token
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(2)
    end

    it "syncs normally if resync_token in headers is the same as the one in process_token" do
      get sync_route, params: {process_token: process_token_without_resync, dsl_version: dsl_version}, headers: headers_with_resync_token
      process_token_with_resync = JSON(response.body)["process_token"]

      get sync_route, params: {process_token: process_token_with_resync, dsl_version: dsl_version}, headers: headers_with_resync_token
      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq(2)
    end
  end

  context "resync_token in request headers is not present" do
    let(:process_token_without_resync) do
      make_process_token(current_facility_processed_since: 1.year.ago)
    end

    it "syncs normally" do
      get sync_route, params: {process_token: process_token_without_resync, dsl_version: dsl_version}, headers: headers
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(3)
      expect(parse_process_token(response_body)[:resync_token]).to eq(nil)

      get sync_route, params: {process_token: JSON(response.body)["process_token"], dsl_version: dsl_version}, headers: headers
      expect(JSON(response.body)[response_key].count).to eq(2)
    end
  end

  it "does a force-resync when mismatch between locale in header and process token" do
    get sync_route, params: {dsl_version: dsl_version}, headers: {"Accept-Language" => "en-IN"}.merge(headers)
    expect(JSON(response.body)["questionnaires"].count).to eq 3
    process_token = JSON(response.body)["process_token"]

    get sync_route, params: {dsl_version: dsl_version, process_token: process_token}, headers: {"Accept-Language" => "en-IN"}.merge(headers)
    expect(JSON(response.body)["questionnaires"].count).to eq 2

    get sync_route, params: {dsl_version: dsl_version, process_token: process_token}, headers: {"Accept-Language" => "hi-IN"}.merge(headers)
    expect(JSON(response.body)["questionnaires"].count).to eq 3
  end
end
