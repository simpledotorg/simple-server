# frozen_string_literal: true

require "rails_helper"

RSpec.describe DuplicatePassportAnalytics do
  describe ".trend" do
    it "allows specifying metrics" do
      Timecop.freeze do
        expect_any_instance_of(described_class).to(
          receive(:trend).with([:across_facilities], 4.months.ago, 2.weeks)
        )

        described_class.trend(metrics: [:across_facilities])
      end
    end

    it "allows specifying all metrics" do
      Timecop.freeze do
        expect_any_instance_of(described_class).to(
          receive(:trend).with(
            [
              :across_facilities,
              :same_facility,
              :across_districts,
              :across_blocks
            ], 4.months.ago, 2.weeks
          )
        )

        described_class.trend(metrics: :all)
      end
    end

    it "throws an error if the wrong metrics are asked for" do
      expect {
        described_class.trend(metrics: [:across_states])
      }.to raise_exception(ArgumentError, "Unknown metrics.")
    end
  end

  describe "#trend" do
    # across_facilities
    before do
      identifier_1 = SecureRandom.uuid
      dupe_patients_across_facilities = create_list(:patient, 2, business_identifiers: [])
      create(:patient_business_identifier, identifier: identifier_1, patient: dupe_patients_across_facilities[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
      create(:patient_business_identifier, identifier: identifier_1, patient: dupe_patients_across_facilities[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})
    end

    it "generates a pdf and attaches it over an email" do
      Timecop.freeze do
        report_email = "test@simple.org"
        create(:admin, email: report_email)
        subject = described_class.new(report_email: report_email)

        expect_any_instance_of(Prawn::Document).to receive(:render)
        expect_any_instance_of(Mail::Message).to receive(:deliver)

        subject.trend([:across_facilities], 4.months.ago, 2.weeks)
      end
    end

    it "doesn't do anything when the email isn't a power_user" do
      Timecop.freeze do
        report_email = "test@simple.org"
        create(:admin)
        subject = described_class.new(report_email: report_email)

        expect_any_instance_of(Prawn::Document).to_not receive(:render)
        expect_any_instance_of(Mail::Message).to_not receive(:deliver)

        subject.trend([:across_facilities], 4.months.ago, 2.weeks)
      end
    end
  end

  describe "#report" do
    # across_facilities
    before do
      identifier_1 = SecureRandom.uuid
      dupe_patients_across_facilities = create_list(:patient, 2, business_identifiers: [])
      create(:patient_business_identifier, identifier: identifier_1, patient: dupe_patients_across_facilities[0], metadata: {assigningFacilityUuid: SecureRandom.uuid})
      create(:patient_business_identifier, identifier: identifier_1, patient: dupe_patients_across_facilities[1], metadata: {assigningFacilityUuid: SecureRandom.uuid})
    end

    # same_facility
    before do
      facility_id = SecureRandom.uuid
      identifier_2 = SecureRandom.uuid
      dupe_patients_in_same_facility = create_list(:patient, 2, business_identifiers: [])
      create_list(:patient_business_identifier, 2, identifier: identifier_2, patient: dupe_patients_in_same_facility[0], metadata: {assigningFacilityUuid: facility_id})
      create_list(:patient_business_identifier, 2, identifier: identifier_2, patient: dupe_patients_in_same_facility[1], metadata: {assigningFacilityUuid: facility_id})
    end

    # across_blocks
    before do
      fg = create(:facility_group)
      identifier_3 = SecureRandom.uuid
      facility_1 = create(:facility, block: "Block A", facility_group: fg)
      facility_2 = create(:facility, block: "Block B", facility_group: fg)
      dupe_patients_across_blocks = create_list(:patient, 2, business_identifiers: [])
      create(:patient_business_identifier, identifier: identifier_3, patient: dupe_patients_across_blocks[0], metadata: {assigningFacilityUuid: facility_1.id})
      create(:patient_business_identifier, identifier: identifier_3, patient: dupe_patients_across_blocks[1], metadata: {assigningFacilityUuid: facility_2.id})
    end

    it "reports all reportable metrics on statsd" do
      expect(Statsd.instance).to receive(:gauge).with("DuplicatePassportAnalytics.duplicate_passports_across_facilities.size", 2)
      expect(Statsd.instance).to receive(:gauge).with("DuplicatePassportAnalytics.duplicate_passports_in_same_facility.size", 1)
      expect(Statsd.instance).to receive(:gauge).with("DuplicatePassportAnalytics.duplicate_passports_across_districts.size", 0)
      expect(Statsd.instance).to receive(:gauge).with("DuplicatePassportAnalytics.duplicate_passports_across_blocks.size", 1)
      expect(Statsd.instance).to receive(:gauge).with("ReportDuplicatePassports.size", 2) # legacy

      described_class.new.report
    end

    it "logs all reportable metrics" do
      expect(Rails.logger).to receive(:info).with(msg: "duplicate_passports_across_facilities are 2")
      expect(Rails.logger).to receive(:info).with(msg: "duplicate_passports_in_same_facility are 1")
      expect(Rails.logger).to receive(:info).with(msg: "duplicate_passports_across_districts are 0")
      expect(Rails.logger).to receive(:info).with(msg: "duplicate_passports_across_blocks are 1")
      expect(Rails.logger).to receive(:info).with(msg: "2 passports have duplicate patients across facilities") # legacy

      described_class.new.report
    end
  end

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
