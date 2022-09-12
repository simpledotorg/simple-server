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

    it "creates call results" do
      patient = create(:patient)
      call_results = (1..3).map {
        build_call_result_payload(build(:call_result, patient: patient))
      }
      set_authentication_headers

      post(:sync_from_user, params: {call_results: call_results}, as: :json)

      expect(CallResult.count).to eq 3
      expect(patient.call_results.count).to eq 3
      expect(response).to have_http_status(200)
    end

    context "when patient_id is not supplied" do
      it "sets the patient_id from the appointment" do
        patient = create(:patient)
        appointment = create(:appointment, patient: patient)
        call_results =
          [build_call_result_payload(build(:call_result, appointment: appointment, patient_id: nil)),
            build_call_result_payload(build(:call_result, appointment: appointment)).except(:patient_id)]

        set_authentication_headers

        post(:sync_from_user, params: {call_results: call_results}, as: :json)

        expect(CallResult.count).to eq 2
        expect(CallResult.pluck(:patient_id)).to all eq patient.id
        expect(response).to have_http_status(200)
      end

      it "leaves the patient_id nil if the appointment does not exist" do
        call_results =
          [build_call_result_payload(build(:call_result, patient_id: nil)),
            build_call_result_payload(build(:call_result)).except(:patient_id)]

        set_authentication_headers

        post(:sync_from_user, params: {call_results: call_results}, as: :json)

        expect(CallResult.count).to eq 2
        expect(CallResult.pluck(:patient_id)).to all be nil
        expect(response).to have_http_status(200)
      end
    end

    context "when facility_id is not supplied" do
      it "sets the facility_id using the header" do
        patient = create(:patient)
        appointment = create(:appointment, patient: patient)
        call_results =
          [build_call_result_payload(build(:call_result, appointment: appointment, facility_id: nil)),
            build_call_result_payload(build(:call_result, appointment: appointment)).except(:facility_id)]

        set_authentication_headers

        post(:sync_from_user, params: {call_results: call_results}, as: :json)

        expect(CallResult.count).to eq 2
        expect(CallResult.pluck(:facility_id)).to all eq request_facility.id
        expect(response).to have_http_status(200)
      end
    end

    context "when patient_id is supplied" do
      it "doesn't override the patient_id if it's supplied already" do
        patient = create(:patient)
        other_patient = create(:patient)
        appointment = create(:appointment, patient: patient)
        call_results =
          [build_call_result_payload(build(:call_result, appointment: appointment, patient: other_patient))]

        set_authentication_headers

        post(:sync_from_user, params: {call_results: call_results}, as: :json)

        expect(CallResult.count).to eq 1
        expect(CallResult.pluck(:patient_id)).to all eq other_patient.id
        expect(response).to have_http_status(200)
      end
    end

    context "when facility_id is supplied" do
      it "doesn't override the facility_id if it's supplied already" do
        facility = create(:facility)
        other_facility = create(:facility)
        appointment = create(:appointment, facility: facility)
        call_results =
          [build_call_result_payload(build(:call_result, appointment: appointment, facility: other_facility))]

        set_authentication_headers

        post(:sync_from_user, params: {call_results: call_results}, as: :json)

        expect(CallResult.count).to eq 1
        expect(CallResult.pluck(:facility_id)).to all eq other_facility.id
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
    it_behaves_like "a working sync controller that supports region level sync"
  end
end
