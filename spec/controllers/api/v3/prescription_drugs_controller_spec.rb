# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::PrescriptionDrugsController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { PrescriptionDrug }
  let(:build_payload) { -> { build_prescription_drug_payload } }
  let(:build_invalid_payload) { -> { build_invalid_prescription_drug_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(prescription_drug) { updated_prescription_drug_payload prescription_drug } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  def create_record(options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create(:prescription_drug, {patient: patient}.merge(options))
  end

  def create_record_list(n, options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create_list(:prescription_drug, n, {patient: patient}.merge(options))
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"
    it_behaves_like "a working sync controller updating records"

    describe "creates new prescription drugs" do
      it "creates new prescription drugs with associated patient, and facility" do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"

        patient = create(:patient)
        facility = create(:facility)
        prescription_drugs = (1..3).map {
          build_prescription_drug_payload(FactoryBot.build(:prescription_drug,
            patient: patient,
            facility: facility))
        }

        post(:sync_from_user, params: {prescription_drugs: prescription_drugs}, as: :json)

        expect(PrescriptionDrug.count).to eq 3
        expect(patient.prescription_drugs.count).to eq 3
        expect(facility.prescription_drugs.count).to eq 3
        expect(response).to have_http_status(200)
      end

      it "creates prescription drugs with teleconsultation information" do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"

        prescription_drugs = (1..3).map {
          build_prescription_drug_payload(FactoryBot.build(:prescription_drug, :for_teleconsultation))
        }

        teleconsultation_ids = prescription_drugs.map { |prescription_drug|
          prescription_drug["teleconsultation_id"]
        }

        post(:sync_from_user, params: {prescription_drugs: prescription_drugs}, as: :json)

        expect(PrescriptionDrug.count).to eq 3
        expect(PrescriptionDrug.pluck(:frequency)).to all eq "OD"
        expect(PrescriptionDrug.pluck(:duration_in_days)).to all eq 10
        expect(PrescriptionDrug.pluck(:teleconsultation_id)).to match_array teleconsultation_ids
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
    it_behaves_like "a working sync controller that supports region level sync"

    describe "patient prioritisation" do
      it "syncs records for patients in the request facility first" do
        request_2_facility = create(:facility, facility_group: request_facility_group)
        create_record_list(2, facility: request_facility, updated_at: 3.minutes.ago)
        create_record_list(2, facility: request_facility, updated_at: 5.minutes.ago)
        create_record_list(2, facility: request_2_facility, updated_at: 7.minutes.ago)
        create_record_list(2, facility: request_2_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: {limit: 4}
        response_1_body = JSON(response.body)

        record_ids = response_1_body["prescription_drugs"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        reset_controller

        # GET request 2
        get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
        response_2_body = JSON(response.body)

        record_ids = response_2_body["prescription_drugs"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end
  end
end
