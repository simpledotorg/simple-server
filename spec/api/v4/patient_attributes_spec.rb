require "swagger_helper"

describe "Patient Attribute V4 API", swagger_doc: "v4/swagger.json" do
  let(:request_user) { create(:user) }
  let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
  let(:HTTP_X_USER_ID) { request_user.id }
  let(:HTTP_X_FACILITY_ID) { request_facility.id }
  let(:Authorization) { "Bearer #{request_user.access_token}" }

  path "/patient_attributes/sync" do
    post "Syncs patient_attributes data from device to server." do
      tags "Patient Attribute"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :patient_attributes, in: :body, schema: Api::V4::Schema.patient_attributes_sync_from_user_request

      response "200", "patient_attributes created" do
        let(:patient_attributes) do
          {patient_attributes: (1..3).map { build(:patient_attribute).attributes.with_payload_keys }}
        end
        run_test!
      end

      response "200", "some, or no errors were found" do
        schema Api::V4::Schema.sync_from_user_errors
        let(:patient_attributes) do
          {patient_attributes: (1..3).map { build(:patient_attribute, :invalid).attributes.with_payload_keys }}
        end
        run_test!
      end

      include_examples "returns 403 for post requests for forbidden users", :patient_attributes
    end

    get "Sync patient attribute data from server to device" do
      tags "Patient Attribute"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      Api::V4::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          create_list(:patient_attribute, 3)
        end
      end

      response "200", "patient attribute received" do
        schema Api::V4::Schema.patient_attributes_sync_to_user_response
        let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
        let(:limit) { 10 }
        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
