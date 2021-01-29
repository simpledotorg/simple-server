require "rails_helper"

RSpec.describe DuplicatePassportAnalytics do
  xdescribe "#trend"

  xdescribe "#report"

  describe "#duplicate_passports_across_facilities" do
    context "for passports with the same identifiers" do
      let!(:identifier) { SecureRandom.uuid }

      it "does not have passports with same patient at the same facility" do
        facility_id = SecureRandom.uuid
        patient = create(:patient, business_identifiers: [])
        create_list(:patient_business_identifier, 2, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_across_facilities.size).to eq(0)
      end

      it "does not have passports with duplicate patients (different by id) at the same facility" do
        facility_id = SecureRandom.uuid
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_across_facilities.size).to eq(0)
      end

      it "does not have passports with the same patient at different facilities" do
        patient = create(:patient, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_across_facilities.size).to eq(0)
      end

      it "only has different patients assigned to a passport at different facilities" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_across_facilities.size).to eq(1)
      end
    end

    context "for passports without the same identifiers" do
      it "does not count them" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_across_facilities.size).to eq(0)
      end
    end
  end

  describe "#duplicate_passports_across_districts" do
    context "for passports with the same identifiers" do
      let!(:identifier) { SecureRandom.uuid }

      it "does not have passports with same patient at the same facility" do
        facility_id = SecureRandom.uuid
        patient = create(:patient, business_identifiers: [])
        create_list(:patient_business_identifier, 2, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_across_districts.size).to eq(0)
      end

      it "does not have passports with duplicate patients (different by id) at the same facility" do
        facility_id = SecureRandom.uuid
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_across_districts.size).to eq(0)
      end

      it "does not have passports with the same patient at different facilities" do
        patient = create(:patient, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_across_districts.size).to eq(0)
      end

      it "does not have passports with duplicate patients (different by id) at the same district" do
        fg = create(:facility_group)
        facility_1 = create(:facility, facility_group: fg)
        facility_2 = create(:facility, facility_group: fg)
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_1.id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_2.id})

        expect(described_class.new.duplicate_passports_across_districts.size).to eq(0)
      end

      it "only has different patients assigned to a passport at different districts" do
        facility_1 = create(:facility, facility_group: create(:facility_group))
        facility_2 = create(:facility, facility_group: create(:facility_group))
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_1.id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_2.id})

        expect(described_class.new.duplicate_passports_across_districts.size).to eq(1)
      end
    end

    context "for passports without the same identifiers" do
      it "does not count them" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_across_districts.size).to eq(0)
      end
    end
  end

  describe "#duplicate_passports_across_blocks" do
    context "for passports with the same identifiers" do
      let!(:identifier) { SecureRandom.uuid }

      it "does not have passports with same patient at the same facility" do
        facility_id = SecureRandom.uuid
        patient = create(:patient, business_identifiers: [])
        create_list(:patient_business_identifier, 2, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_across_blocks.size).to eq(0)
      end

      it "does not have passports with duplicate patients (different by id) at the same facility" do
        facility_id = SecureRandom.uuid
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_across_blocks.size).to eq(0)
      end

      it "does not have passports with the same patient at different facilities" do
        patient = create(:patient, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_across_blocks.size).to eq(0)
      end

      it "does not have passports with duplicate patients (different by id) at the same block" do
        fg = create(:facility_group)
        facility_1 = create(:facility, block: "Block A", facility_group: fg)
        facility_2 = create(:facility, block: "Block A", facility_group: fg)
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_1.id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_2.id})

        expect(described_class.new.duplicate_passports_across_blocks.size).to eq(0)
      end

      it "only has different patients assigned to a passport at different blocks" do
        fg = create(:facility_group)
        facility_1 = create(:facility, block: "Block A", facility_group: fg)
        facility_2 = create(:facility, block: "Block B", facility_group: fg)
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_1.id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_2.id})

        expect(described_class.new.duplicate_passports_across_blocks.size).to eq(1)
      end
    end

    context "for passports without the same identifiers" do
      it "does not count them" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_across_blocks.size).to eq(0)
      end
    end
  end

  describe "#duplicate_passports_without_next_appointments" do
    context "for passports with the same identifiers" do
      let!(:identifier) { SecureRandom.uuid }

      it "does not have passports with same patient at the same facility without a next appointment scheduled" do
        facility_id = SecureRandom.uuid
        patient = create(:patient, business_identifiers: [])
        create_list(:patient_business_identifier, 2, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_without_next_appointments.size).to eq(0)
      end

      it "does not have passports with duplicate patients (different by id) at the same facility without a next appointment scheduled" do
        facility_id = SecureRandom.uuid
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_id})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_without_next_appointments.size).to eq(0)
      end

      it "does not have passports with the same patient at different facilities without a next appointment scheduled" do
        patient = create(:patient, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_without_next_appointments.size).to eq(0)
      end

      it "does not have passports with the same patient at different facilities with a next appointment scheduled" do
        patient = create(:patient, business_identifiers: [])
        _appointment = create(:appointment, patient: patient)
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_without_next_appointments.size).to eq(0)
      end

      it "only has passports for different patients assigned at different facilities without a next appointment scheduled" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_without_next_appointments.size).to eq(1)
      end
    end

    context "for passports without the same identifiers" do
      it "does not count them" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_without_next_appointments.size).to eq(0)
      end
    end
  end

  describe "#duplicate_passports_in_same_facility" do
    context "for passports with the same identifiers" do
      let!(:identifier) { SecureRandom.uuid }

      it "does not have passports with the same patient at different facilities" do
        patient = create(:patient, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patient, metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_in_same_facility.size).to eq(0)
      end

      it "does not have passport with duplicate patients at different facilities" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_in_same_facility.size).to eq(0)
      end

      it "only has passports with duplicate patients at the same facility" do
        facility_id = SecureRandom.uuid
        patients = create_list(:patient, 2, business_identifiers: [])
        create_list(:patient_business_identifier, 2, identifier: identifier, patient: patients[0], metadata: {assigningFacilityUuid: facility_id})
        create_list(:patient_business_identifier, 2, identifier: identifier, patient: patients[1], metadata: {assigningFacilityUuid: facility_id})

        expect(described_class.new.duplicate_passports_in_same_facility.size).to eq(1)
      end
    end

    context "for passports without the same identifiers" do
      it "does not count them" do
        patients = create_list(:patient, 2, business_identifiers: [])
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
        create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

        expect(described_class.new.duplicate_passports_in_same_facility.size).to eq(0)
      end
    end
  end

  describe "#duplicate_passports_with_actually_different_patients" do
    let!(:identifier) { SecureRandom.uuid }

    it "can be called and does not break" do
      patients = create_list(:patient, 2, business_identifiers: [])
      create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
      create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patients[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})

      expect(described_class.new.duplicate_passports_with_actually_different_patients.size).to_not be_nil
    end
  end
end
