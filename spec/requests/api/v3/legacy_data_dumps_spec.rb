require "rails_helper"

RSpec.describe "Legacy Data Dumps", type: :request do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { request_user.facility }

  let(:headers) do
    {
      "HTTP_X_USER_ID" => request_user.id,
      "HTTP_X_FACILITY_ID" => request_facility.id,
      "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}",
      "HTTP_X_APP_VERSION" => "2024.1.0",
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json"
    }
  end

  describe "POST /api/v3/legacy_data_dumps" do
    let(:valid_payload) do
      {
        legacy_data_dump: {
          patients: [
            {
              id: SecureRandom.uuid,
              full_name: "Test Patient",
              age: 45,
              gender: "male",
              status: "active"
            }
          ],
          medical_histories: [
            {
              id: SecureRandom.uuid,
              patient_id: SecureRandom.uuid,
              prior_heart_attack: "yes",
              diabetes: "unknown"
            }
          ],
          blood_pressures: [
            {
              id: SecureRandom.uuid,
              patient_id: SecureRandom.uuid,
              systolic: 140,
              diastolic: 90
            }
          ],
          blood_sugars: [
            {
              id: SecureRandom.uuid,
              patient_id: SecureRandom.uuid,
              blood_sugar_type: "random",
              blood_sugar_value: 180
            }
          ],
          prescription_drugs: [
            {
              id: SecureRandom.uuid,
              patient_id: SecureRandom.uuid,
              name: "Amlodipine",
              dosage: "5mg"
            }
          ],
          appointments: [
            {
              id: SecureRandom.uuid,
              patient_id: SecureRandom.uuid,
              scheduled_date: "2024-02-01",
              status: "scheduled"
            }
          ],
          encounters: [
            {
              id: SecureRandom.uuid,
              patient_id: SecureRandom.uuid,
              notes: "Follow-up visit"
            }
          ]
        }
      }
    end

    it "creates a legacy data dump successfully" do
      expect {
        post "/api/v3/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers
      }.to change(LegacyMobileDataDump, :count).by(1)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("ok")
      expect(json_response["id"]).to be_present
    end

    it "stores the raw payload with all legacy data" do
      post "/api/v3/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: headers

      dump = LegacyMobileDataDump.last

      expect(dump.raw_payload["patients"]).to be_present
      expect(dump.raw_payload["medical_histories"]).to be_present
      expect(dump.raw_payload["blood_pressures"]).to be_present
      expect(dump.raw_payload["blood_sugars"]).to be_present
      expect(dump.raw_payload["prescription_drugs"]).to be_present
      expect(dump.raw_payload["appointments"]).to be_present
      expect(dump.raw_payload["encounters"]).to be_present
    end

    it "records the user who made the dump" do
      post "/api/v3/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: headers

      dump = LegacyMobileDataDump.last
      expect(dump.user).to eq(request_user)
    end

    it "records the mobile version from headers" do
      post "/api/v3/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: headers

      dump = LegacyMobileDataDump.last
      expect(dump.mobile_version).to eq("2024.1.0")
    end

    it "records the dump date" do
      freeze_time do
        post "/api/v3/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers

        dump = LegacyMobileDataDump.last
        expect(dump.dump_date).to be_within(1.second).of(Time.current)
      end
    end

    it "returns unauthorized with invalid token" do
      invalid_headers = headers.merge("HTTP_AUTHORIZATION" => "Bearer invalid_token")

      post "/api/v3/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: invalid_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns bad request without facility id" do
      invalid_headers = headers.except("HTTP_X_FACILITY_ID")

      post "/api/v3/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: invalid_headers

      expect(response).to have_http_status(:bad_request)
    end
  end
end
