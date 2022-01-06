# frozen_string_literal: true

require "swagger_helper"

describe "Teleconsultations v4 API", swagger_doc: "v4/swagger.json" do
  path "/teleconsultations/sync" do
    post "Syncs Teleconsultations from device to server." do
      tags "Teleconsultations"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :teleconsultations, in: :body, schema: Api::V4::Schema.teleconsultation_sync_from_user_request

      response "200", "teleconsultations created" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:teleconsultations) { {teleconsultations: [build_teleconsultation_payload]} }

        run_test!
      end

      include_examples "returns 403 for post requests for forbidden users", :teleconsultations
    end
  end
end
