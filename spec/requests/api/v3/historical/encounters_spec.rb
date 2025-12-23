require "rails_helper"

RSpec.describe "Historical Encounters Sync", type: :request do
  let(:request_user) { FactoryBot.create(:user) }

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

    payload = build_encounter_payload(encounter)

    payload["encountered_on"] = Date.tomorrow

    post sync_route,
         params: { encounters: [payload] }.to_json,
         headers: headers

    expect(response).to have_http_status(:ok)
    expect(Encounter.exists?(encounter.id)).to be(true)
  end
end
