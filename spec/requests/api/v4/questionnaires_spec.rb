require "swagger_helper"

RSpec.describe "api/v4/questionnaires", type: :request do
  path "/api/v4/questionnaires/sync" do
    get("Syncs questionnaires from server to device") do
      tags "Questionnaires"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :questionnaires, in: :body, schema: Api::V4::Schema.questionnaires_sync_to_user_response
      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
