# Historical sync endpoints are designed to bypass validations for legacy data.

require "rails_helper"

RSpec.describe "Historical Prescription Drugs Sync", type: :request do
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

  let(:sync_route) { "/api/v3/historical/prescription_drugs/sync" }
  let(:patient) { FactoryBot.create(:patient, registration_facility: request_user.facility) }

  it "syncs legacy prescription drugs and normalizes invalid enum values" do
    pd = FactoryBot.build(:prescription_drug, patient: patient, facility: request_user.facility)
    payload = build_prescription_drug_payload(pd)

    payload["is_protocol_drug"] = "true" 
    payload["frequency"] = "once_a_day"     

    post sync_route,
         params: { prescription_drugs: [payload] }.to_json,
         headers: headers

    expect(response).to have_http_status(:ok)

    record = PrescriptionDrug.find(pd.id)
    expect(record.frequency).to be_nil
  end
end
