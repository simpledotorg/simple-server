# frozen_string_literal: true

require "swagger_helper"

describe "Protocols v3 API", swagger_doc: "v3/swagger.json" do
  path "/protocols/sync" do
    get "Syncs protocols and protocol drugs data from server to device." do
      tags "protocol"
      Api::V3::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          protocol = FactoryBot.create(:protocol)
          FactoryBot.create_list(:protocol_drug, 3, protocol: protocol)
        end
      end

      response "200", "protocols received" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V3::Schema.protocol_sync_to_user_response
        let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }

        before do |example|
          submit_request(example.metadata)
        end

        it "returns a valid 201 response" do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end
    end
  end
end
