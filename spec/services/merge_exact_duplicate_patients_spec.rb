require "rails_helper"

RSpec.describe MergeExactDuplicatePatients do
  describe "#perform" do
    # check if report_stats has the right numbers
    # catches any exceptions and reports them
    # if one of them fails all of them don't fail
  end

  describe "#duplicate_patient_ids" do
    it "finds patients with same identifier and case insensitive full name" do
      patient_1 = create(:patient, full_name: "Patient")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      patient_3 = create(:patient, full_name: "PATient")
      patient_3.business_identifiers.first.update(identifier: passport_id)

      expect(described_class.new.duplicate_patient_ids.first).to match_array [patient_1.id, patient_2.id, patient_3.id]
    end

    it "does not return patients with same identifier but different name" do
      patient_1 = create(:patient, full_name: "Patient 1")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient 2")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      expect(described_class.new.duplicate_patient_ids).to be_empty
    end

    it "does not return patients with different identifier but same name" do
      create(:patient, full_name: "Patient")
      create(:patient, full_name: "Patient")

      expect(described_class.new.duplicate_patient_ids).to be_empty
    end

    it "does not return a patient who has the more than one identifiers" do
      patient = create(:patient, full_name: "Patient")
      create(:patient_business_identifier, identifier: patient.business_identifiers.first.identifier, patient: patient)

      expect(described_class.new.duplicate_patient_ids).to be_empty
    end
  end
end
