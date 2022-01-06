# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientImport::Validator do
  describe "#validate" do
    it "validates its parameters using API validators" do
      params = [{
        patient: {property: "patient property"},
        medical_history: {property: "medical history property"},
        blood_pressures: [{property: "bp1 property"}, {property: "bp2 property"}],
        prescription_drugs: [{property: "pd1 property"}, {property: "pd2 property"}]
      }]

      patient_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      medical_history_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      blood_pressure_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      prescription_drug_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))

      allow(Api::V3::PatientPayloadValidator).to receive(:new).and_return(patient_payload_validator)
      allow(Api::V3::MedicalHistoryPayloadValidator).to receive(:new).and_return(medical_history_payload_validator)
      allow(Api::V3::BloodPressurePayloadValidator).to receive(:new).and_return(blood_pressure_payload_validator)
      allow(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).and_return(prescription_drug_payload_validator)

      expect(Api::V3::PatientPayloadValidator).to receive(:new).with(property: "patient property", skip_facility_authorization: true)
      expect(Api::V3::MedicalHistoryPayloadValidator).to receive(:new).with(property: "medical history property")
      expect(Api::V3::BloodPressurePayloadValidator).to receive(:new).with(property: "bp1 property")
      expect(Api::V3::BloodPressurePayloadValidator).to receive(:new).with(property: "bp2 property")
      expect(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).with(property: "pd1 property")
      expect(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).with(property: "pd2 property")

      validator = PatientImport::Validator.new(params)

      validator.validate
    end
  end

  describe "#errors" do
    it "returns index-wise errors" do
      params = [{
        patient: {property: "patient property"},
        medical_history: {property: "medical history property"},
        blood_pressures: [{property: "bp1 property"}, {property: "bp2 property"}],
        prescription_drugs: [{property: "pd1 property"}, {property: "pd2 property"}]
      }]

      patient_payload_validator = double(valid?: false, errors: OpenStruct.new(full_messages: ["invalid patient"]))
      medical_history_payload_validator = double(valid?: false, errors: OpenStruct.new(full_messages: ["invalid medical_history"]))
      blood_pressure_payload_validator = double(valid?: false, errors: OpenStruct.new(full_messages: ["invalid blood_pressure"]))
      prescription_drug_payload_validator = double(valid?: false, errors: OpenStruct.new(full_messages: ["invalid prescription_drug"]))

      allow(Api::V3::PatientPayloadValidator).to receive(:new).and_return(patient_payload_validator)
      allow(Api::V3::MedicalHistoryPayloadValidator).to receive(:new).and_return(medical_history_payload_validator)
      allow(Api::V3::BloodPressurePayloadValidator).to receive(:new).and_return(blood_pressure_payload_validator)
      allow(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).and_return(prescription_drug_payload_validator)

      expect(Api::V3::PatientPayloadValidator).to receive(:new).with(property: "patient property", skip_facility_authorization: true)
      expect(Api::V3::MedicalHistoryPayloadValidator).to receive(:new).with(property: "medical history property")
      expect(Api::V3::BloodPressurePayloadValidator).to receive(:new).with(property: "bp1 property")
      expect(Api::V3::BloodPressurePayloadValidator).to receive(:new).with(property: "bp2 property")
      expect(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).with(property: "pd1 property")
      expect(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).with(property: "pd2 property")

      validator = PatientImport::Validator.new(params)

      validator.validate

      expect(validator.errors).to eq(
        0 => [
          "invalid patient",
          "invalid medical_history",
          "invalid blood_pressure",
          "invalid blood_pressure",
          "invalid prescription_drug",
          "invalid prescription_drug"
        ]
      )
    end
  end

  describe "valid?" do
    it "is true when no validation errors are present" do
      params = [{
        patient: {property: "patient property"},
        medical_history: {property: "medical history property"},
        blood_pressures: [{property: "bp1 property"}, {property: "bp2 property"}],
        prescription_drugs: [{property: "pd1 property"}, {property: "pd2 property"}]
      }]

      patient_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      medical_history_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      blood_pressure_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      prescription_drug_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))

      allow(Api::V3::PatientPayloadValidator).to receive(:new).and_return(patient_payload_validator)
      allow(Api::V3::MedicalHistoryPayloadValidator).to receive(:new).and_return(medical_history_payload_validator)
      allow(Api::V3::BloodPressurePayloadValidator).to receive(:new).and_return(blood_pressure_payload_validator)
      allow(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).and_return(prescription_drug_payload_validator)

      validator = PatientImport::Validator.new(params)

      expect(validator).to be_valid
    end

    it "is false when any validation errors are present" do
      params = [{
        patient: {property: "patient property"},
        medical_history: {property: "medical history property"},
        blood_pressures: [{property: "bp1 property"}, {property: "bp2 property"}],
        prescription_drugs: [{property: "pd1 property"}, {property: "pd2 property"}]
      }]

      patient_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      medical_history_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: ["this one doesn't work"]))
      blood_pressure_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))
      prescription_drug_payload_validator = double(valid?: true, errors: OpenStruct.new(full_messages: []))

      allow(Api::V3::PatientPayloadValidator).to receive(:new).and_return(patient_payload_validator)
      allow(Api::V3::MedicalHistoryPayloadValidator).to receive(:new).and_return(medical_history_payload_validator)
      allow(Api::V3::BloodPressurePayloadValidator).to receive(:new).and_return(blood_pressure_payload_validator)
      allow(Api::V3::PrescriptionDrugPayloadValidator).to receive(:new).and_return(prescription_drug_payload_validator)

      validator = PatientImport::Validator.new(params)

      expect(validator).not_to be_valid
    end
  end
end
