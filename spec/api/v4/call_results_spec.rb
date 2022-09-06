require "swagger_helper"

describe "CallResults v4 API", swagger_doc: "v4/swagger.json" do
  path "/call_results/sync" do
    post "Syncs call_result data from device to server." do
      tags "Call Result"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :call_results, in: :body, schema: Api::V4::Schema.call_result_sync_from_user_request

      response "200", "call_results created" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:call_results) { {call_results: (1..3).map { build_call_result_payload }} }

        run_test!
      end

      response "200", "some, or no errors were found" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        schema Api::V4::Schema.sync_from_user_errors

        let(:call_results) { {call_results: (1..3).map { build_invalid_call_result_payload }} }
        run_test!
      end

      include_examples "returns 403 for post requests for forbidden users", :call_results
    end

    get "Syncs call results data from server to device." do
      tags "Call Results"
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

      response "200", "call result received" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V4::Schema.call_result_sync_to_user_response
        let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
