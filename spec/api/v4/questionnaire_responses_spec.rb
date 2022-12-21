require "swagger_helper"

xdescribe "Questionnaire Responses v4 API", swagger_doc: "v4/swagger.json" do
  path "/questionnaire_responses/sync" do
    post("Syncs Questionnaire Responses from Device to Server") do
      tags "Questionnaire Responses"

      security [access_token: [], user_id: [], facility_id: []]

      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid

      parameter name: :questionnaire_responses, in: :body, schema: Api::V4::Schema.questionnaire_responses_sync_from_user_request

      response "200", "Questionnaire Responses created" do
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
        schema Api::V4::Schema.questionnaire_responses_sync_to_user_response
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
