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

  # include_examples "v4 API sync requests"

  it "does a force-resync when mismatch between locale in header and process token" do
    dsl_version = 1
    mock_questionnaire_types(3).keys.take(3).each do |questionnaire_type|
      create(:questionnaire, questionnaire_type: questionnaire_type)
    end

    get sync_route, params: {dsl_version: dsl_version}, headers: { "Accept-Language" => "en-IN" }.merge(headers)
    expect(JSON(response.body)["questionnaires"].count).to eq 3
    process_token = JSON(response.body)["process_token"]

    get sync_route, params: {dsl_version: dsl_version, process_token: process_token}, headers: { "Accept-Language" => "en-IN" }.merge(headers)
    expect(JSON(response.body)["questionnaires"].count).to eq 1

    get sync_route, params: {dsl_version: dsl_version, process_token: process_token}, headers: { "Accept-Language" => "hi-IN" }.merge(headers)
    expect(JSON(response.body)["questionnaires"].count).to eq 3
  end
end
