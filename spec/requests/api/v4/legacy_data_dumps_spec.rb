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

  describe "POST /api/v4/legacy_data_dumps" do
    let(:valid_payload) do
      {
        patients: [
          {
            id: SecureRandom.uuid,
            full_name: "Test Patient",
            age: 45,
            gender: "male",
            status: "active",

            medical_histories: [
              {
                id: SecureRandom.uuid,
                diabetes: "unknown",
                prior_heart_attack: "yes"
              }
            ],

            blood_pressures: [
              {
                id: SecureRandom.uuid,
                systolic: 140,
                diastolic: 90
              }
            ],

            blood_sugars: [
              {
                id: SecureRandom.uuid,
                blood_sugar_type: "random",
                blood_sugar_value: 180
              }
            ],

            prescription_drugs: [
              {
                id: SecureRandom.uuid,
                name: "Amlodipine",
                dosage: "5mg"
              }
            ],

            appointments: [
              {
                id: SecureRandom.uuid,
                scheduled_date: "2024-02-01",
                status: "scheduled"
              }
            ],

            encounters: [
              {
                id: SecureRandom.uuid,
                notes: "Follow-up visit"
              }
            ]
          }
        ]
      }
    end

    it "creates a legacy data dump successfully" do
      expect {
        post "/api/v4/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers
      }.to change(LegacyMobileDataDump, :count).by(1)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["errors"]).to eq([])
    end

    it "returns sync controller format response on success" do
      post "/api/v4/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json).to have_key("errors")
      expect(json["errors"]).to be_an(Array)
      expect(json["errors"]).to eq([])
    end

    it "stores the raw payload with nested legacy data per patient" do
      post "/api/v4/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: headers

      dump = LegacyMobileDataDump.last
      expect(dump.raw_payload["patients"]).to be_present

      patient = dump.raw_payload["patients"].first

      expect(patient["medical_histories"]).to be_present
      expect(patient["blood_pressures"]).to be_present
      expect(patient["blood_sugars"]).to be_present
      expect(patient["prescription_drugs"]).to be_present
      expect(patient["appointments"]).to be_present
      expect(patient["encounters"]).to be_present
    end

    it "records the user who made the dump" do
      post "/api/v4/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: headers

      dump = LegacyMobileDataDump.last
      expect(dump.user).to eq(request_user)
    end

    it "records the mobile version from headers" do
      post "/api/v4/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: headers

      dump = LegacyMobileDataDump.last
      expect(dump.mobile_version).to eq("2024.1.0")
    end

    it "records the dump date" do
      freeze_time do
        post "/api/v4/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers

        dump = LegacyMobileDataDump.last
        expect(dump.dump_date).to be_within(1.second).of(Time.current)
      end
    end

    it "returns unauthorized with invalid token" do
      invalid_headers = headers.merge("HTTP_AUTHORIZATION" => "Bearer invalid_token")

      post "/api/v4/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: invalid_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns bad request without facility id" do
      invalid_headers = headers.except("HTTP_X_FACILITY_ID")

      post "/api/v4/legacy_data_dumps",
        params: valid_payload.to_json,
        headers: invalid_headers

      expect(response).to have_http_status(:bad_request)
    end

    context "when validation fails" do
      let(:invalid_dump) do
        LegacyMobileDataDump.new(
          raw_payload: {},
          dump_date: Time.current.utc,
          user: request_user
        ).tap do |dump|
          dump.errors.add(:raw_payload, "can't be blank")
        end
      end

      before do
        allow(LegacyMobileDataDump).to receive(:new).and_return(invalid_dump)
        allow(invalid_dump).to receive(:save).and_return(false)
      end

      it "returns errors in sync controller format with 200 OK status" do
        post "/api/v4/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
        expect(json["errors"]).to be_an(Array)
        expect(json["errors"]).not_to be_empty
      end

      it "returns error hash with field names and error messages" do
        post "/api/v4/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers

        json = JSON.parse(response.body)
        error_hash = json["errors"].first

        expect(error_hash).to be_a(Hash)
        expect(error_hash).to have_key("raw_payload")
        expect(error_hash["raw_payload"]).to be_an(Array)
        expect(error_hash["raw_payload"]).to include("can't be blank")
      end

      it "includes id key in error hash (nil when validation fails before save)" do
        post "/api/v4/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers

        json = JSON.parse(response.body)
        error_hash = json["errors"].first

        expect(error_hash).to have_key("id")
        expect(error_hash["id"]).to be_nil
      end

      it "returns errors for invalid data" do
        invalid_dump.errors.add(:dump_date, "is invalid")

        post "/api/v4/legacy_data_dumps",
          params: valid_payload.to_json,
          headers: headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        error_hash = json["errors"].first

        expect(error_hash).to be_a(Hash)
        expect(error_hash.keys).to include("id", "raw_payload", "dump_date")
      end

      it "does not create a dump when validation fails" do
        expect {
          post "/api/v4/legacy_data_dumps",
            params: valid_payload.to_json,
            headers: headers
        }.not_to change(LegacyMobileDataDump, :count)
      end
    end
  end
end
