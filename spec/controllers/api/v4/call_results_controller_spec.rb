require "rails_helper"

RSpec.describe Api::V4::CallResultsController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { CallResult }
  let(:build_payload) { -> { build_call_result_payload } }
  let(:build_invalid_payload) { -> { build_invalid_call_result_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(call_result) { updated_call_result_payload call_result } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  def create_record(options = {result_type: :agreed_to_visit})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create(:call_result, {patient: patient}.merge(options))
  end

  def create_record_list(n, options = {result_type: :agreed_to_visit})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create_list(:call_result, n, {patient: patient}.merge(options))
  end

  it_behaves_like "a sync controller that authenticates user requests: sync_from_user"
  it_behaves_like "a sync controller that audits the data access: sync_from_user"

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"
    it_behaves_like "a working sync controller updating records"

    it "sets the patient_id if it's not supplied" do

    end

    it "sets the facility_id if it's not supplied" do

    end

    it "doesn't override the patient_id if it's supplied already" do

    end

    it "doesn't override the facility_id if it's supplied already" do

    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
    it_behaves_like "a working sync controller that supports region level sync"
  end
end
