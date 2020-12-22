require "rails_helper"

RSpec.describe ReportDuplicatePassports do
  describe ".duplicate_passports" do
    context "for passports with the same identifiers" do
      let!(:identifier) { SecureRandom.uuid }

      it "does not have passports with same patient at the same facility" do
        facility_id = SecureRandom.uuid
        patient = create(:patient, business_identifiers: [])
        create_list(:patient_business_identifier, 2, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.duplicate_passports).to be_empty
      end

      it "does not have passports with duplicate patients (different by id) at the same facility" do
        facility_id = SecureRandom.uuid
        patients = create_list(:patient, 2, business_identifiers: [])
        patients.map do |patient|
          create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: facility_id})
        end

        expect(described_class.duplicate_passports).to be_empty
      end

      it "does not have passports with the same patient assigned to it at different facilities" do
        patient = create(:patient, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.duplicate_passports).to be_empty
      end

      it "only has different patients assigned to a passport at different facilities" do
        patients = create_list(:patient, 2, business_identifiers: [])
        identifiers =
          [create(:patient_business_identifier, identifier: identifier, patient: patients.first, metadata: {assigningFacilityUuid: SecureRandom.uuid}),
            create(:patient_business_identifier, identifier: identifier, patient: patients.second, metadata: {assigningFacilityUuid: SecureRandom.uuid})]

        expect(described_class.duplicate_passports).to match_array identifiers
        expect(described_class.duplicate_passports_count).to eq described_class.duplicate_passports.group(:identifier).count.keys.count
      end
    end

    context "for passports without the same identifiers" do
      it "does not count them" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients.first, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients.second, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.duplicate_passports).to be_empty
      end
    end
  end
end
