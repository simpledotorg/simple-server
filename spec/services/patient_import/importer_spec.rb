require "rails_helper"

RSpec.describe PatientImport::Importer do
  describe "#call" do
    it "imports patient information" do
      facility = create(:facility)
      admin = create(:admin)
      params = [{
        patient: {property: "patient property"},
        medical_history: {property: "medical history property"},
        blood_pressures: [{property: "bp1 property"}, {property: "bp2 property"}],
        prescription_drugs: [{property: "pd1 property"}, {property: "pd2 property"}],
      }]

      new_patient = create(:patient)
      new_bp = create(:blood_pressure)
      new_medical_history = create(:medical_history)
      new_prescription_drug = create(:prescription_drug)

      importer = PatientImport::Importer.new(params: params, facility: facility, admin: admin)

      allow(Api::V3::PatientTransformer).to receive(:from_nested_request).and_call_original
      allow(Api::V3::MedicalHistoryTransformer).to receive(:from_request).and_call_original
      allow(Api::V3::BloodPressureTransformer).to receive(:from_request).and_call_original
      allow(Api::V3::PrescriptionDrugTransformer).to receive(:from_request).and_call_original

      allow_any_instance_of(MergePatientService).to receive(:merge).and_return(new_patient)
      allow(importer).to receive(:merge_encounter_observation).and_return(new_bp)
      allow(MedicalHistory).to receive(:merge).and_return(new_medical_history)
      allow(PrescriptionDrug).to receive(:merge).and_return(new_prescription_drug)

      expect(MergePatientService).to receive(:new).with(
        hash_including(property: "patient property"),
        request_metadata: {
          request_facility_id: facility.id,
          request_user_id: PatientImport::ImportUser.find_or_create.id
        }
      ).and_call_original
      expect(importer).to receive(:merge_encounter_observation).with(:blood_pressures, hash_including(property: "bp1 property"))
      expect(importer).to receive(:merge_encounter_observation).with(:blood_pressures, hash_including(property: "bp2 property"))
      expect(MedicalHistory).to receive(:merge).with(hash_including(property: "medical history property"))
      expect(PrescriptionDrug).to receive(:merge).with(hash_including(property: "pd1 property"))
      expect(PrescriptionDrug).to receive(:merge).with(hash_including(property: "pd2 property"))

      importer.call
    end

    it "creates patient import logs" do
      facility = create(:facility)
      admin = create(:admin)
      params = [{
        patient: {property: "patient property"},
        medical_history: {property: "medical history property"},
        blood_pressures: [{property: "bp1 property"}, {property: "bp2 property"}],
        prescription_drugs: [{property: "pd1 property"}, {property: "pd2 property"}],
      }]

      new_patient = create(:patient)
      new_bp = create(:blood_pressure)
      new_medical_history = create(:medical_history)
      new_prescription_drug = create(:prescription_drug)

      importer = PatientImport::Importer.new(params: params, facility: facility, admin: admin)

      allow(Api::V3::PatientTransformer).to receive(:from_nested_request).and_call_original
      allow(Api::V3::MedicalHistoryTransformer).to receive(:from_request).and_call_original
      allow(Api::V3::BloodPressureTransformer).to receive(:from_request).and_call_original
      allow(Api::V3::PrescriptionDrugTransformer).to receive(:from_request).and_call_original

      allow_any_instance_of(MergePatientService).to receive(:merge).and_return(new_patient)
      allow(importer).to receive(:merge_encounter_observation).and_return(new_bp)
      allow(MedicalHistory).to receive(:merge).and_return(new_medical_history)
      allow(PrescriptionDrug).to receive(:merge).and_return(new_prescription_drug)

      importer.call

      expect(PatientImportLog.find_by(user: admin, record: new_patient)).to be_present
      expect(PatientImportLog.find_by(user: admin, record: new_bp)).to be_present
      expect(PatientImportLog.find_by(user: admin, record: new_medical_history)).to be_present
      expect(PatientImportLog.find_by(user: admin, record: new_prescription_drug)).to be_present
    end
  end
end
