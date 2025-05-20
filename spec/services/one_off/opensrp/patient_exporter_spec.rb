require "rails_helper"

RSpec.describe OneOff::Opensrp::PatientExporter do
  describe "#fhir_patient_address" do
    it "is {} when the patient has no address" do
      patient = create(:patient, address: nil)

      expect(patient.address).to be_nil

      exporter = OneOff::Opensrp::PatientExporter.new(patient, {})

      expect(exporter.fhir_patient_address).to eq({})
    end
  end

  describe "#address_text" do
    it "is empty string when patient has no address" do
      patient = create(:patient, address: nil)

      expect(patient.address).to be_nil

      exporter = OneOff::Opensrp::PatientExporter.new(patient, {})

      expect(exporter.address_text).to eq("")
    end
  end
end
