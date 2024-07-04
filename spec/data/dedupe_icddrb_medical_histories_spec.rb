require "rails_helper"
require Rails.root.join("db", "data", "20240117114102_dedupe_icddrb_medical_histories.rb")

describe DedupeIcddrbMedicalHistories do
  before do
    allow(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")
  end

  describe "when the data migration is run" do
    it "deduplicates medical histories and deletes older medical history records" do
      facility = create(:facility, id: "f472c5db-188f-4563-9bc7-9f86a6ed6403")
      patients = create_list(:patient, 3, :without_medical_history, assigned_facility_id: facility.id)

      medical_history1 = create(:medical_history, patient: patients[0], hypertension: "yes", diabetes: "no")

      medical_history2 = create(:medical_history, patient: patients[1], hypertension: "yes", diabetes: "no")
      medical_history3 = create(:medical_history, patient: patients[1], hypertension: "no", diabetes: "no")
      medical_history4 = create(:medical_history, patient: patients[1], hypertension: "no", diabetes: "yes")

      medical_history5 = create(:medical_history, patient: patients[2], hypertension: "no", diabetes: "no")
      medical_history6 = create(:medical_history, patient: patients[2], hypertension: "no", diabetes: "no")

      described_class.new.up

      deduped_patient2 = MedicalHistory.find_by(patient_id: patients[1].id)
      deduped_patient3 = MedicalHistory.find_by(patient_id: patients[2].id)

      expect(medical_history1.reload.deleted_at).to be_nil

      expect(medical_history2.reload.deleted_at).to be_a(Time)
      expect(medical_history3.reload.deleted_at).to be_a(Time)
      expect(medical_history4.reload.deleted_at).to be_a(Time)
      expect(deduped_patient2).to have_attributes(hypertension: "yes", diabetes: "yes")

      expect(medical_history5.reload.deleted_at).to be_a(Time)
      expect(medical_history6.reload.deleted_at).to be_a(Time)
      expect(deduped_patient3).to have_attributes(hypertension: "no", diabetes: "no")
    end
  end
end
