require "rails_helper"

RSpec.describe "Historical Appointments Sync", type: :request do
  let(:request_user) { FactoryBot.create(:user) }
  let(:headers) do
    {"HTTP_X_USER_ID" => request_user.id,
     "HTTP_X_FACILITY_ID" => request_user.facility.id,
     "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}",
     "ACCEPT" => "application/json",
     "CONTENT_TYPE" => "application/json"}
  end
  let(:sync_route) { "/api/v3/historical/appointments/sync" }
  let(:patient) { FactoryBot.create(:patient, registration_facility: request_user.facility) }

  it "syncs appointments ignoring active model validations" do
    app = FactoryBot.build(:appointment, patient: patient, facility: request_user.facility)
    payload = build_appointment_payload(app)
    payload['status'] = "not_started"
    payload['cancel_reason'] = nil

    post sync_route, params: { appointments: [payload] }.to_json, headers: headers

    expect(response).to have_http_status(200)
    record = Appointment.find(app.id)
    expect(record.status).to be_nil 
  end
end
