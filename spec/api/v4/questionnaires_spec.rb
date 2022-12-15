require "swagger_helper"

xdescribe "Questionnaires v4 API", swagger_doc: "v4/swagger.json" do
  path "/questionnaires/sync" do
    get "Syncs Questionnaires from Server to Device" do
      tags "Questionnaires"

      security [access_token: [], user_id: [], facility_id: []]

      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: "HTTP_ACCEPT_LANGUAGE", in: :header, type: :string

      Api::V4::Schema.sync_to_user_request.each do |param|
        parameter param
      end
      parameter name: "questionnaires_api_version", in: :query, type: :string

      response "200", "Questionnaires Synced to user device" do
        schema Api::V4::Schema.questionnaires_sync_to_user_response
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
