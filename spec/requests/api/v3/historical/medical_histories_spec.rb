require "rails_helper"

RSpec.describe "Historical Medical Histories Sync", type: :request do
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

  let(:sync_route) { "/api/v3/historical/medical_histories/sync" }
  let(:patient) { FactoryBot.create(:patient, registration_facility: request_user.facility) }

  it "normalizes invalid enum values to nil while syncing legacy medical history data" do
    medical_history = FactoryBot.build(:medical_history, patient: patient)
    payload = build_medical_history_payload(medical_history)

    payload["diabetes"] = "maybe"
    payload["hypertension"] = "sometimes"

    post sync_route,
      params: {medical_histories: [payload]}.to_json,
      headers: headers

    expect(response).to have_http_status(:ok)

    record = MedicalHistory.find(medical_history.id)
    expect(record.diabetes).to be_nil
    expect(record.hypertension).to be_nil
  end
end
