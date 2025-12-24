# Historical sync endpoints are designed to bypass validations for legacy data.

require "rails_helper"

RSpec.describe "Historical Blood Sugars Sync", type: :request do
  let(:request_user) { FactoryBot.create(:user) }
  let(:headers) do
    {"HTTP_X_USER_ID" => request_user.id,
     "HTTP_X_FACILITY_ID" => request_user.facility.id,
     "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}",
     "ACCEPT" => "application/json",
     "CONTENT_TYPE" => "application/json"}
  end
  let(:sync_route) { "/api/v3/historical/blood_sugars/sync" }
  let(:patient) { FactoryBot.create(:patient, registration_facility: request_user.facility) }

  it "syncs blood sugars ignoring active model validations" do
    bs = FactoryBot.build(:blood_sugar, patient: patient, facility: request_user.facility)
    payload = build_blood_sugar_payload(bs)
    payload["blood_sugar_value"] = "99990000000000000"

    post sync_route, params: {blood_sugars: [payload]}.to_json, headers: headers

    expect(response).to have_http_status(200)
    record = BloodSugar.find(bs.id)
    expect(record.blood_sugar_value).to eq(9.999e16)
  end
end
