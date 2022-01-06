# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientDeduplication::Strategies do
  describe "#identifier_and_full_name_match" do
    it "finds patients with same identifier and case insensitive full name" do
      patient_1 = create(:patient, full_name: "Patient")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      patient_3 = create(:patient, full_name: "PATient")
      patient_3.business_identifiers.first.update(identifier: passport_id)

      expect(described_class.identifier_and_full_name_match.first).to match_array [patient_1.id, patient_2.id, patient_3.id]
    end

    it "does not return patients with same identifier but different name" do
      patient_1 = create(:patient, full_name: "Patient 1")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient 2")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      expect(described_class.identifier_and_full_name_match).to be_empty
    end

    it "does not return patients with different identifier but same name" do
      create(:patient, full_name: "Patient")
      create(:patient, full_name: "Patient")

      expect(described_class.identifier_and_full_name_match).to be_empty
    end

    it "does not return a patient who has the more than one identifiers" do
      patient = create(:patient, full_name: "Patient")
      create(:patient_business_identifier, identifier: patient.business_identifiers.first.identifier, patient: patient)

      expect(described_class.identifier_and_full_name_match).to be_empty
    end
  end

  describe "#identifier_excluding_full_name_match" do
    it "finds patients with the same identifier without matching names" do
      patient_1 = create(:patient, full_name: "Patient one")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient two")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      create(:patient, full_name: "Patient three")

      expect(described_class.identifier_excluding_full_name_match.first).to match_array [patient_1.id, patient_2.id]
    end

    it "does not include patients with the same full name" do
      patient_1 = create(:patient, full_name: "Patient one")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient one")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      expect(described_class.identifier_excluding_full_name_match).to be_empty
    end

    it "optionally returns only a given number of matches" do
      patient_one = create(:patient, full_name: "Patient one")
      patient_one_passport_id = patient_one.business_identifiers.first.identifier

      patient_one_dup = create(:patient, full_name: "Patient one dup")
      patient_one_dup.business_identifiers.first.update(identifier: patient_one_passport_id)

      patient_2 = create(:patient, full_name: "Patient two")
      patient_2_passport_id = patient_2.business_identifiers.first.identifier

      patient_2_dup = create(:patient, full_name: "Patient two dup")
      patient_2_dup.business_identifiers.first.update(identifier: patient_2_passport_id)

      expect(described_class.identifier_excluding_full_name_match(limit: 1).count).to eq 1
      expect(described_class.identifier_excluding_full_name_match.count).to eq 2
    end

    it "scopes results to facilities" do
      patient = create(:patient, full_name: "Patient one")
      patient_passport_id = patient.business_identifiers.first.identifier

      patient_dup = create(:patient, full_name: "Patient one dup")
      patient_dup.business_identifiers.first.update(identifier: patient_passport_id)

      other_facility = create(:facility)

      expect(described_class.identifier_excluding_full_name_match_for_facilities(facilities: [patient.registration_facility]).count).to eq 1
      expect(described_class.identifier_excluding_full_name_match_for_facilities(facilities: [patient_dup.registration_facility]).count).to eq 1
      expect(described_class.identifier_excluding_full_name_match_for_facilities(facilities: [other_facility]).count).to eq 0
    end

    it "does not include matches from disallowed identifier types" do
      patient_1 = create(:patient, full_name: "Patient 1")
      patient_1.business_identifiers.first.update!(identifier_type: "ethiopia_medical_record")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient 2")
      patient_2.business_identifiers.first.update(identifier: passport_id, identifier_type: "ethiopia_medical_record")

      expect(described_class.identifier_excluding_full_name_match).to be_empty
    end

    it "does not return patients with same identifiers but different types" do
      patient_1 = create(:patient, full_name: "Patient 1")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient 2")
      patient_2.business_identifiers.first.update(identifier: passport_id, identifier_type: "bangladesh_national_id")

      expect(described_class.identifier_excluding_full_name_match).to be_empty
    end
  end
end
