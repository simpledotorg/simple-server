# frozen_string_literal: true

require "swagger_helper"

describe "BloodSugars v4 API", swagger_doc: "v4/swagger.json" do
  path "/blood_sugars/sync" do
    post "Syncs blood sugar data from device to server." do
      tags "Blood Sugar"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :blood_sugars, in: :body, schema: Api::V4::Schema.blood_sugar_sync_from_user_request

      response "200", "blood sugars created" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:blood_sugars) { {blood_sugars: (1..3).map { build_blood_sugar_payload }} }

        run_test!
      end

      response "200", "some, or no errors were found" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V4::Schema.sync_from_user_errors
        let(:blood_sugars) { {blood_sugars: (1..3).map { build_invalid_blood_sugar_payload }} }

        run_test!
      end

      include_examples "returns 403 for post requests for forbidden users", :blood_sugars
    end

    get "Syncs blood sugar data from server to device." do
      tags "Blood Sugar"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      Api::V4::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          create_list(:blood_sugar, 3)
        end
      end

      response "200", "blood sugar received" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V4::Schema.blood_sugar_sync_to_user_response
        let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
