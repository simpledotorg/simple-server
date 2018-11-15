require 'swagger_helper'

describe 'Facilities API', swagger_doc: 'current/swagger.json' do
  path '/facilities/sync' do
    get 'Syncs facilities data from server to device.' do
      tags 'facility'
      security [ basic: [] ]

      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid
      Api::Current::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          facility = FactoryBot.create(:facility)
        end
      end

      response '200', 'facilities received' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { FactoryBot.create(:user_facility, user: request_user).facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        schema Api::Current::Schema.facility_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }

        run_test!
      end
    end
  end
end

