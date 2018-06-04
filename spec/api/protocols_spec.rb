require 'swagger_helper'

describe 'Protocols API' do
  path '/protocols/sync' do

    get 'Syncs protocols and protocol drugs data from server to device.' do
      tags 'protocol'
      Api::V1::Spec.sync_to_user_request_spec.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          protocol = FactoryBot.create(:protocol)
          FactoryBot.create_list(:protocol_drug, 10, protocol: protocol)
        end
      end

      response '200', 'protocols received' do
        schema Api::V1::Spec.protocol_sync_to_user_response_spec
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