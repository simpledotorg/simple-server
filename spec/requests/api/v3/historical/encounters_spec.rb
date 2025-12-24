require "rails_helper"

RSpec.describe "Historical Encounters Sync", type: :request do
  let(:request_user) { FactoryBot.create(:user) }

  around do |example|
    Flipper.enable(:sync_encounters)
    example.run
    Flipper.disable(:sync_encounters)
  end

  let(:headers) do
    {
      "HTTP_X_USER_ID" => request_user.id,
      "HTTP_X_FACILITY_ID" => request_user.facility.id,
      "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}",
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:sync_route) { "/api/v3/historical/encounters/sync" }
  let(:patient) { FactoryBot.create(:patient, registration_facility: request_user.facility) }

  it "persists encounters from historical sync without enforcing model validations" do
    encounter = FactoryBot.build(
      :encounter,
      patient: patient,
      facility: request_user.facility
    )

    payload = build_encounters_payload(encounter)

    payload["encountered_on"] = Date.tomorrow

    post sync_route,
      params: {encounters: [payload]}.to_json,
      headers: headers

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)

    expect(json["errors"]).to be_empty
    expect(Encounter.exists?(json["processed"].first)).to be(true)
  end

  it "accepts encounters with observations missing user_id that are rejected by normal v3 encounters sync" do
    encounter = FactoryBot.build(
      :encounter,
      patient: patient,
      facility: request_user.facility
    )

    bp = FactoryBot.build(:blood_pressure, patient: patient, facility: request_user.facility)
    bp_payload = bp.attributes.with_payload_keys

    payload = build_encounters_payload(encounter)
    payload["observations"] = {"blood_pressures" => [bp_payload]}

    bp = payload["observations"]["blood_pressures"].first
    bp.delete("user_id")

    body = {encounters: [payload]}

    # 1) Normal v3 encounters sync should reject this payload via EncounterPayloadValidator
    post "/api/v3/encounters/sync",
      params: body.to_json,
      headers: headers

    expect(response).to have_http_status(:ok)
    normal_json = JSON.parse(response.body)

    expect(normal_json["errors"]).to include(a_hash_including("id" => payload["id"], "schema" => kind_of(Array)))
    expect(Encounter.where(id: payload["id"]).count).to eq(0)

    # 2) Historical encounters sync should accept the same payload and persist the encounter
    post sync_route,
      params: body.to_json,
      headers: headers

    expect(response).to have_http_status(:ok)
    historical_json = JSON.parse(response.body)

    expect(historical_json["errors"]).to be_empty
    expect(historical_json["processed"]).to include(payload["id"])
    expect(Encounter.where(id: payload["id"]).count).to eq(1)
  end
end
