require "rails_helper"

RSpec.describe "Historical Patients Sync", type: :request do
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

  let(:sync_route) { "/api/v3/historical/patients/sync" }

  it "syncs legacy patient data and normalizes invalid enum values to nil" do
    patient = FactoryBot.build(
      :patient,
      registration_facility: request_user.facility,
      age: 20,
      status: "active"
    )

    payload = build_patient_payload(patient)

    payload["date_of_birth"] = "2099-01-01"
    payload["status"] = "zombie"

    post sync_route,
      params: {patients: [payload]}.to_json,
      headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON(response.body)["processed"]).to include(patient.id)

    record = Patient.find(patient.id)
    expect(record.date_of_birth.to_s).to eq("2099-01-01")
    expect(record.status).to be_nil
  end
end
