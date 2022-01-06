# frozen_string_literal: true

require "swagger_helper"

describe "Appointment v3 API", swagger_doc: "v3/swagger.json" do
  path "/appointments/sync" do
    post "Syncs appointment data from device to server." do
      tags "Appointments"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :appointments, in: :body, schema: Api::V3::Schema.appointment_sync_from_user_request

      response "200", "appointments created" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:appointments) { {appointments: (1..3).map { build_appointment_payload }} }

        run_test!
      end

      response "200", "some, or no errors were found" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:appointments) { {appointments: (1..3).map { build_invalid_appointment_payload }} }
        run_test!
      end

      include_examples "returns 403 for post requests for forbidden users", :appointments
    end

    get "Syncs appointment data from server to device." do
      tags "Appointments"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      Api::V3::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:appointment, 3)
        end
      end

      response "200", "appointments received" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V3::Schema.appointment_sync_to_user_response
        let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }

        before do |example|
          submit_request(example.metadata)
        end

        it "returns a valid 201 response" do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
