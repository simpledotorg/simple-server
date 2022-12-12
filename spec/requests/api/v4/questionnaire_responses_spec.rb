require 'swagger_helper'

RSpec.describe 'api/v4/questionnaire_responses', type: :request do

  path '/api/v4/questionnaire_responses/sync' do

    get('Syncs questionnaire responses from server to device') do
      tags "Questionnaire Responses"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :appointments, in: :body, schema: Api::V4::Schema.questionnaire_responses_sync_to_user_response
      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end

    post('Syncs questionnaire responses from device to server') do
      tags "Questionnaire Responses"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :appointments, in: :body, schema: Api::V4::Schema.questionnaire_responses_sync_from_user_request

      response(201, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      include_examples "returns 403 for post requests for forbidden users", :questionnaire_responses
    end
  end
end
