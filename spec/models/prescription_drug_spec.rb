# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrescriptionDrug, type: :model do
  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  describe "Associations" do
    it { should belong_to(:facility).optional }
    it { should belong_to(:patient).optional }
    it { should belong_to(:teleconsultation).optional }
  end

  describe "Scopes" do
    describe ".for_sync" do
      it "includes discarded prescription drugs" do
        discarded_prescription_drug = create(:prescription_drug, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_prescription_drug)
      end
    end
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe ".prescribed_as_of" do
    def remove_drug(prescription_drug, time)
      prescription_drug.update(is_deleted: true, device_updated_at: time)
    end

    let!(:patient) { create(:patient) }
    let!(:initial_visit_time) { Time.parse "01 Jan 2020 14:30" }
    let!(:latest_visit_time) { Time.parse "15 Jan 2020 14:30" }
    let!(:prescription_drugs) do
      Timecop.freeze(initial_visit_time) do
        create_list(:prescription_drug, 2,
          is_protocol_drug: true,
          patient: patient,
          facility: patient.registration_facility,
          user: patient.registration_user)
      end
    end

    it "returns no prescription drugs for dates before the initial visit" do
      expect(described_class.prescribed_as_of(initial_visit_time.to_date - 1.day)).to be_empty
    end

    it "returns all prescription drugs for the day of initial visit" do
      expect(described_class.prescribed_as_of(initial_visit_time.to_date)).to match_array prescription_drugs
    end

    it "returns all prescription drugs for later visit dates" do
      expect(described_class.prescribed_as_of(latest_visit_time.to_date)).to match_array prescription_drugs
    end

    context "when a drug is removed in a visit" do
      let!(:visit_time) { Time.parse "10 Jan 2020 14:30" }
      before { remove_drug(prescription_drugs.first, visit_time) }

      it "returns all prescription drugs for dates before the visit" do
        expect(described_class.prescribed_as_of(visit_time.to_date - 1.day)).to match_array prescription_drugs
      end

      it "does not return the removed prescription drug for the visit date" do
        expect(described_class.prescribed_as_of(visit_time.to_date)).to contain_exactly prescription_drugs.second
      end

      it "does not return the removed prescription drug on later visit dates" do
        expect(described_class.prescribed_as_of(latest_visit_time.to_date)).to contain_exactly prescription_drugs.second
      end
    end
  end

  context "anonymised data for prescription drugs" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the prescription drug" do
        prescription_drug = create(:prescription_drug)

        anonymised_data =
          {id: Hashable.hash_uuid(prescription_drug.id),
           patient_id: Hashable.hash_uuid(prescription_drug.patient_id),
           created_at: prescription_drug.created_at,
           registration_facility_name: prescription_drug.facility.name,
           user_id: Hashable.hash_uuid(prescription_drug.patient.registration_user.id),
           medicine_name: prescription_drug.name,
           dosage: prescription_drug.dosage}

        expect(prescription_drug.anonymized_data).to eq anonymised_data
      end
    end
  end
end
