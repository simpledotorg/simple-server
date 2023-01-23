require "swagger_helper"

describe "Questionnaire Responses v4 API", swagger_doc: "v4/swagger.json" do
  path "/questionnaire_responses/sync" do
    post("Syncs Questionnaire Responses from Device to Server") do
      tags "Questionnaire Responses"

      security [access_token: [], user_id: [], facility_id: []]

      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid

      parameter name: :questionnaire_responses, in: :body, schema: Api::V4::Schema.questionnaire_responses_sync_from_user_request

      response "200", "questionnaire responses created" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:questionnaire_responses) { {questionnaire_responses: (1..3).map { build_questionnaire_response_payload }} }

        schema Api::V4::Schema.sync_from_user_errors
        run_test!
      end

      response "200", "some, or no errors were found" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:questionnaire_responses) { {questionnaire_responses: (1..3).map { build_questionnaire_response_payload }} }

        schema Api::V4::Schema.sync_from_user_errors
        run_test!
      end

      include_examples "returns 403 for post requests for forbidden users", :questionnaire_responses
    end

    get("Syncs Questionnaire Responses from Server to Device") do
      tags "Questionnaire Responses"

      security [access_token: [], user_id: [], facility_id: []]

      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid

      Api::V4::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      response "200", "Questionnaires Synced to user device" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V4::Schema.questionnaire_responses_sync_to_user_response
        let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
