# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::MedicalHistoriesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { MedicalHistory }
  let(:build_payload) { -> { build_medical_history_payload } }
  let(:build_invalid_payload) { -> { build_invalid_medical_history_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(medical_history) { updated_medical_history_payload medical_history } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  def create_record(options = {})
    facility = create(:facility, facility_group: request_facility_group)
    patient = build(:patient, registration_facility: facility)
    create(:medical_history, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    facility = create(:facility, facility_group_id: request_facility_group.id)
    patient = build(:patient, registration_facility_id: facility.id)
    create_list(:medical_history, n, options.merge(patient: patient).except(:facility))
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"
    it_behaves_like "a working sync controller updating records"
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"

    context "patient prioritisation" do
      let(:facility_in_same_group) { create(:facility, facility_group: request_facility_group) }
      let(:patient_in_request_facility) { build(:patient, registration_facility: request_facility) }
      let(:patient_in_same_group) { build(:patient, registration_facility: facility_in_same_group) }

      it "syncs records for patients in the request facility first" do
        create_list(:medical_history, 2, patient: patient_in_request_facility, updated_at: 3.minutes.ago)
        create_list(:medical_history, 2, patient: patient_in_request_facility, updated_at: 5.minutes.ago)
        create_list(:medical_history, 2, patient: patient_in_same_group, updated_at: 7.minutes.ago)
        create_list(:medical_history, 2, patient: patient_in_same_group, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: {limit: 4}
        response_1_body = JSON(response.body)

        response_1_record_ids = response_1_body["medical_histories"].map { |r| r["id"] }
        response_1_records = model.where(id: response_1_record_ids)
        expect(response_1_records.count).to eq 4
        expect(response_1_records.map(&:patient).to_set).to eq Set[patient_in_request_facility]

        reset_controller

        # GET request 2
        get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
        response_2_body = JSON(response.body)

        response_2_record_ids = response_2_body["medical_histories"].map { |r| r["id"] }
        response_2_records = model.where(id: response_2_record_ids)
        expect(response_2_records.count).to eq 4
        expect(response_2_records.map(&:patient).to_set).to eq Set[patient_in_request_facility, patient_in_same_group]
      end
    end
  end

  describe "#sync_from_user" do
    let(:params) do
      {
        medical_histories: [{
          id: SecureRandom.uuid,
          patient_id: patient.id,
          prior_heart_attack_boolean: nil,
          prior_stroke_boolean: nil,
          chronic_kidney_disease_boolean: nil,
          receiving_treatment_for_hypertension_boolean: nil,
          diabetes_boolean: nil,
          diagnosed_with_hypertension_boolean: nil,
          prior_heart_attack: "no",
          prior_stroke: "no",
          chronic_kidney_disease: "no",
          receiving_treatment_for_hypertension: "no",
          diabetes: "no",
          diagnosed_with_hypertension: "no",
          hypertension: "no",
          receiving_treatment_for_diabetes: "yes",
          created_at: DateTime.current,
          updated_at: DateTime.current
        }]
      }
    end

    before :each do
      request.env["HTTP_X_USER_ID"] = request_user.id
      request.env["HTTP_X_FACILITY_ID"] = request_facility.id
    end

    context "with a pre-existing medical history" do
      let(:patient) { create(:patient) }

      it "returns 200 and updates existing medical history" do
        medical_history = patient.medical_history
        # updating timestamp because mergeable module won't merge in changes if timestamps match
        medical_history.update(device_updated_at: 10.minutes.ago)

        params[:medical_histories][0][:id] = patient.medical_history.id
        params[:medical_histories][0][:receiving_treatment_for_diabetes] = "unknown"

        expect {
          post :sync_from_user, params: params
        }.to change { patient.reload.medical_history.receiving_treatment_for_diabetes }.from("no").to("unknown")
        expect(response.status).to eq 200
      end
    end

    context "without a pre-existing medical history" do
      let(:patient) { create(:patient, :without_medical_history) }

      it "returns 200 and creates a patient medical history with valid inputs" do
        post :sync_from_user, params: params

        expect(response.status).to eq 200
        history = patient.reload.medical_history
        expected_values = params[:medical_histories].first

        expect(history.id).to eq(expected_values[:id])
        expect(history.patient_id).to eq(expected_values[:patient_id])
        expect(history.prior_heart_attack_boolean).to eq(expected_values[:prior_heart_attack_boolean])
        expect(history.prior_stroke_boolean).to eq(expected_values[:prior_stroke_boolean])
        expect(history.chronic_kidney_disease_boolean).to eq(expected_values[:chronic_kidney_disease_boolean])
        expect(history.receiving_treatment_for_hypertension_boolean).to eq(expected_values[:receiving_treatment_for_hypertension_boolean])
        expect(history.diabetes_boolean).to eq(expected_values[:diabetes_boolean])
        expect(history.diagnosed_with_hypertension_boolean).to eq(expected_values[:diagnosed_with_hypertension_boolean])
        expect(history.prior_heart_attack).to eq(expected_values[:prior_heart_attack])
        expect(history.prior_stroke).to eq(expected_values[:prior_stroke])
        expect(history.chronic_kidney_disease).to eq(expected_values[:chronic_kidney_disease])
        expect(history.receiving_treatment_for_hypertension).to eq(expected_values[:receiving_treatment_for_hypertension])
        expect(history.diabetes).to eq(expected_values[:diabetes])
        expect(history.diagnosed_with_hypertension).to eq(expected_values[:diagnosed_with_hypertension])
        expect(history.hypertension).to eq(expected_values[:hypertension])
        expect(history.receiving_treatment_for_diabetes).to eq(expected_values[:receiving_treatment_for_diabetes])
      end

      it "leaves values at nil when not provided" do
        params[:medical_histories][0].delete(:receiving_treatment_for_diabetes)

        post :sync_from_user, params: params

        expect(response.status).to eq 200
        expect(patient.reload.medical_history.receiving_treatment_for_diabetes).to eq(nil)
      end

      it "returns 200 but returns errors and does not create a medical history when provided invalid values" do
        params[:medical_histories][0][:receiving_treatment_for_diabetes] = "probably"
        post :sync_from_user, params: params

        expect(response.status).to eq 200
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["errors"][0]["schema"][0]).to start_with(
          "The property '#/receiving_treatment_for_diabetes' value \"probably\" did not match one of the following values: yes, no, unknown in schema"
        )
        expect(patient.reload.medical_history).to eq(nil)
      end
    end
  end
end
