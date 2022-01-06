# frozen_string_literal: true

require "swagger_helper"

describe "Facility Teleconsultations v4 API", swagger_doc: "v4/swagger.json" do
  path "/facility_teleconsultations/{facility_id}" do
    get "Fetch a facility's teleconsultation phone number" do
      tags "Teleconsultation"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :facility_id, in: :path, type: :string, description: "Facility UUID"

      let!(:request_user) { create(:user) }
      let!(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
      let!(:HTTP_X_USER_ID) { request_user.id }
      let!(:HTTP_X_FACILITY_ID) { request_facility.id }
      let!(:Authorization) { "Bearer #{request_user.access_token}" }
      let(:facility_id) { request_facility.id }

      response "200", "Teleconsultation phone number is returned" do
        schema Api::V4::Schema.facility_teleconsultations_response
        run_test!
      end

      response "401", "User not authorized" do
        let(:Authorization) { "Bearer not-an-access-token" }
        run_test!
      end
    end
  end
end
