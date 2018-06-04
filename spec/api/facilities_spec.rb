require 'swagger_helper'

describe 'Facilities API' do
  path '/facilities/sync' do
    get 'Syncs facilities data from server to device.' do
      tags 'facility'
      Api::V1::Spec.sync_to_user_request_spec.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          facility = FactoryBot.create(:facility)
        end
      end

      response '200', 'facilities received' do
        schema Api::V1::Spec.facility_sync_to_user_response_spec
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }

        before do |example|
          submit_request(example.metadata)
        end

        it 'returns a valid 201 response' do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end
    end
  end
end

