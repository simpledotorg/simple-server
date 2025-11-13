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
          htn_diagnosed_at: 1.year.ago.round,
          dm_diagnosed_at: 6.months.ago.round,
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
            htn_diagnosed_at: 2.years.ago.iso8601,
            dm_diagnosed_at: 1.year.ago.iso8601,
            created_at: existing_medical_history.created_at.iso8601,
            updated_at: Time.current.iso8601
          }]
        }
      end

      it "returns 200 with validation errors when trying to change existing diagnosis dates" do
        post :sync_from_user, params: params

        expect(response.status).to eq 200
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["errors"]).to be_present
        expect(parsed_body["errors"].first.values.join).to include("cannot be changed")
      end

      it "does not update the diagnosis dates" do
        original_htn = existing_medical_history.htn_diagnosed_at
        original_dm = existing_medical_history.dm_diagnosed_at

        post :sync_from_user, params: params
        existing_medical_history.reload
        expect(existing_medical_history.htn_diagnosed_at).to eq original_htn
        expect(existing_medical_history.dm_diagnosed_at).to eq original_dm
      end
    end

    context "when updating medical history without changing diagnosis dates" do
      let(:existing_medical_history) do
        create(:medical_history,
          patient: patient,
          htn_diagnosed_at: 1.year.ago.round,
          dm_diagnosed_at: 6.months.ago.round,
          device_updated_at: 10.minutes.ago)
      end

      let(:params) do
        {
          medical_histories: [{
            id: existing_medical_history.id,
            patient_id: patient.id,
            prior_heart_attack: "yes",
            prior_stroke: "no",
            chronic_kidney_disease: "no",
            receiving_treatment_for_hypertension: "yes",
            receiving_treatment_for_diabetes: "no",
            diabetes: "no",
            hypertension: "yes",
            diagnosed_with_hypertension: "yes",
            smoking: "no",
            smokeless_tobacco: "no",
            htn_diagnosed_at: existing_medical_history.htn_diagnosed_at.utc.iso8601,
            dm_diagnosed_at: existing_medical_history.dm_diagnosed_at.utc.iso8601,
            created_at: existing_medical_history.created_at.utc.iso8601,
            updated_at: Time.current.utc.iso8601
          }]
        }
      end

      it "successfully updates the medical history" do
        post :sync_from_user, params: params

        expect(response.status).to eq 200
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["errors"]).to be_blank

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
            htn_diagnosed_at: 1.year.ago.round.iso8601,
            dm_diagnosed_at: 6.months.ago.round.iso8601,
            created_at: Time.current.iso8601,
            updated_at: Time.current.iso8601
          }]
        }
      end

      it "successfully creates the medical history with diagnosis dates" do
        expect {
          post :sync_from_user, params: params
        }.to change { MedicalHistory.count }.by_at_least(1)

        expect(response.status).to eq 200
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["errors"]).to be_blank
      end
    end
  end
end
