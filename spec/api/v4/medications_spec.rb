# frozen_string_literal: true

require "swagger_helper"

describe "Medications v4 API", swagger_doc: "v4/swagger.json" do
  path "/medications/sync" do
    get "Syncs medication data from server to device." do
      tags "Medication"
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      Api::V4::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      response "200", "returns medications" do
        let(:request_facility) { create(:facility) }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }

        schema Api::V4::Schema.medication_sync_to_user_response
        let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }
        run_test!
      end
    end
  end
end
