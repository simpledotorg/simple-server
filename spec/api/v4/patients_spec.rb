# frozen_string_literal: true

require "swagger_helper"

describe "Patient Lookup v4 API", swagger_doc: "v4/swagger.json" do
  path "/patients/lookup" do
    post "Lookup a patient all their records synchronously given their full business identifier" do
      tags "Patient"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :body, in: :body, schema: Api::V4::Schema.lookup_request

      response "200", "patient lookup successful" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:patient) { create(:patient, registration_user: request_user, registration_facility: request_facility) }
        let(:body) { {identifier: patient.business_identifiers.first.identifier} }
        schema Api::V4::Schema.lookup_response
        run_test!
      end

      response "404", "No patients found with this identifier" do
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:body) { {identifier: "this-identifier-is-not-present"} }

        run_test!
      end
    end
  end
end
