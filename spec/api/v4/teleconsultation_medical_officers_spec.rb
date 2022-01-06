# frozen_string_literal: true

require "swagger_helper"

describe "Facility Medical Officers v4 API", swagger_doc: "v4/swagger.json" do
  path "/facility_medical_officers/sync" do
    get "Syncs Teleconsultation MOs data from server to device." do
      tags "Teleconsult MOs"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid

      response "200", "facility teleconsult MOs received" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V4::Schema.facility_medical_officers_sync_to_user_response
        let(:limit) { 10 }

        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
