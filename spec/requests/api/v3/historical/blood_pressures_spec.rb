require "rails_helper"

RSpec.describe "Historical Blood Pressures Sync", type: :request do
  let(:request_user) { FactoryBot.create(:user) }
  let(:headers) do
    {"HTTP_X_USER_ID" => request_user.id,
     "HTTP_X_FACILITY_ID" => request_user.facility.id,
     "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}",
     "ACCEPT" => "application/json",
     "CONTENT_TYPE" => "application/json"}
  end
  let(:sync_route) { "/api/v3/historical/blood_pressures/sync" }
  let(:patient) { FactoryBot.create(:patient, registration_facility: request_user.facility) }

  it "syncs blood pressures via historical sync without enforcing validation rules" do
    bp = FactoryBot.build(:blood_pressure, patient: patient, facility: request_user.facility, systolic: 350)
    payload = build_blood_pressure_payload(bp)
    payload["systolic"] = 350

    post sync_route, params: {blood_pressures: [payload]}.to_json, headers: headers

    expect(response).to have_http_status(200)
    expect(JSON(response.body)["errors"]).to be_empty

    record = BloodPressure.find(bp.id)
    expect(record.systolic).to eq(350)
  end
end
