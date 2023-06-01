require "swagger_helper"

describe "Questionnaires v4 API", swagger_doc: "v4/swagger.json" do
  path "/questionnaires/sync" do
    get "Syncs Questionnaires from Server to Device" do
      tags "Questionnaires"

      security [access_token: [], user_id: [], facility_id: []]

      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: "Accept-Language", in: :header, type: :string

      parameter name: "dsl_version", in: :query, type: :string, required: true, description: "The version of layout supported by client."
      Api::V4::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      let("Accept-Language") { "en-IND" }
      let(:dsl_version) { "1.1" }

      response "200", "Questionnaires Synced to user device" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V4::Schema.questionnaires_sync_to_user_response
        let(:process_token) { Base64.encode64({current_facility_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }

        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
