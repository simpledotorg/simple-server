require 'swagger_helper'

describe 'Medical History V1 API', swagger_doc: 'v1/swagger.json' do
  path '/medical_histories/sync' do

    post 'Syncs medical_history data from device to server.' do
      tags 'Medical History'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: :medical_histories, in: :body, schema: Api::V1::Schema.medical_history_sync_from_user_request

      response '200', 'medical_histories created' do
        let(:request_user) { FactoryBot.create(:master_user, :with_phone_number_authentication) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:medical_histories) { { medical_histories: (1..10).map { build_medical_history_payload_v1 } } }

        run_test!
      end

      response '200', 'some, or no errors were found' do
        let(:request_user) { FactoryBot.create(:master_user, :with_phone_number_authentication) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V1::Schema.sync_from_user_errors
        let(:medical_histories) { { medical_histories: (1..10).map { build_invalid_medical_history_payload_v1 } } }
        run_test!
      end
    end

    get 'Syncs medical_history data from server to device.' do
      tags 'Medical History'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      Api::V1::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:medical_history, 10)
        end
      end

      response '200', 'medical_histories received' do
        let(:request_user) { FactoryBot.create(:master_user, :with_phone_number_authentication) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V1::Schema.medical_history_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        run_test!
      end
    end
  end
end