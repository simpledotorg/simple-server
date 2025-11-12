require "rails_helper"

RSpec.describe Api::V3::MedicalHistoriesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:patient) { create(:patient, registration_facility: request_facility) }

  before { set_authentication_headers }

  describe "immutable diagnosis dates validation" do
    context "when updating an existing medical history with diagnosis dates" do
      let(:existing_medical_history) do
        create(:medical_history,
          patient: patient,
          htn_diagnosed_at: 1.year.ago,
          dm_diagnosed_at: 6.months.ago,
          device_updated_at: 10.minutes.ago)
      end

      let(:params) do
        {
          medical_histories: [{
            id: existing_medical_history.id,
            patient_id: patient.id,
            prior_heart_attack: "no",
            prior_stroke: "no",
            chronic_kidney_disease: "no",
            receiving_treatment_for_hypertension: "yes",
            receiving_treatment_for_diabetes: "no",
            diabetes: "no",
            hypertension: "yes",
            diagnosed_with_hypertension: "yes",
            smoking: "no",
            smokeless_tobacco: "no",
            htn_diagnosed_at: 2.years.ago, # Trying to change existing date
            dm_diagnosed_at: 1.year.ago, # Trying to change existing date
            created_at: existing_medical_history.created_at,
            updated_at: Time.current
          }]
        }
      end

      it "returns 200 with validation errors when trying to change existing diagnosis dates" do
        post :sync_from_user, params: params

        expect(response.status).to eq 200
        parsed_body = JSON.parse(response.body)

        expect(parsed_body["errors"]).to be_present
        expect(parsed_body["errors"].length).to eq 1

        error = parsed_body["errors"].first
        expect(error["id"]).to eq existing_medical_history.id
        expect(error["htn_diagnosed_at"]).to include("has already been recorded and cannot be changed")
        expect(error["dm_diagnosed_at"]).to include("has already been recorded and cannot be changed")
      end

      it "does not update the diagnosis dates" do
        original_htn_date = existing_medical_history.htn_diagnosed_at
        original_dm_date = existing_medical_history.dm_diagnosed_at

        post :sync_from_user, params: params

        existing_medical_history.reload
        expect(existing_medical_history.htn_diagnosed_at).to eq original_htn_date
        expect(existing_medical_history.dm_diagnosed_at).to eq original_dm_date
      end
    end

    context "when updating medical history without changing diagnosis dates" do
      let(:existing_medical_history) do
        create(:medical_history,
          patient: patient,
          htn_diagnosed_at: 1.year.ago,
          dm_diagnosed_at: 6.months.ago,
          device_updated_at: 10.minutes.ago)
      end

      let(:params) do
        {
          medical_histories: [{
            id: existing_medical_history.id,
            patient_id: patient.id,
            prior_heart_attack: "yes", # Changing this field
            prior_stroke: "no",
            chronic_kidney_disease: "no",
            receiving_treatment_for_hypertension: "yes",
            receiving_treatment_for_diabetes: "no",
            diabetes: "no",
            hypertension: "yes",
            diagnosed_with_hypertension: "yes",
            smoking: "no",
            smokeless_tobacco: "no",
            htn_diagnosed_at: existing_medical_history.htn_diagnosed_at, # Same date
            dm_diagnosed_at: existing_medical_history.dm_diagnosed_at, # Same date
            created_at: existing_medical_history.created_at,
            updated_at: Time.current
          }]
        }
      end

      it "successfully updates the medical history" do
        post :sync_from_user, params: params

        expect(response.status).to eq 200
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["errors"]).to be_nil

        existing_medical_history.reload
        expect(existing_medical_history.prior_heart_attack).to eq "yes"
      end
    end

    context "when creating a new medical history with diagnosis dates" do
      let(:params) do
        {
          medical_histories: [{
            id: SecureRandom.uuid,
            patient_id: patient.id,
            prior_heart_attack: "no",
            prior_stroke: "no",
            chronic_kidney_disease: "no",
            receiving_treatment_for_hypertension: "yes",
            receiving_treatment_for_diabetes: "no",
            diabetes: "no",
            hypertension: "yes",
            diagnosed_with_hypertension: "yes",
            smoking: "no",
            smokeless_tobacco: "no",
            htn_diagnosed_at: 1.year.ago,
            dm_diagnosed_at: 6.months.ago,
            created_at: Time.current,
            updated_at: Time.current
          }]
        }
      end

      it "successfully creates the medical history with diagnosis dates" do
        expect {
          post :sync_from_user, params: params
        }.to change { MedicalHistory.count }.by(1)

        expect(response.status).to eq 200
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["errors"]).to be_nil

        medical_history = MedicalHistory.find(params[:medical_histories].first[:id])
        expect(medical_history.htn_diagnosed_at).to be_present
        expect(medical_history.dm_diagnosed_at).to be_present
      end
    end
  end
end
