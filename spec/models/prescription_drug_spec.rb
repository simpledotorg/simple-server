require "rails_helper"

RSpec.describe PrescriptionDrug, type: :model do
  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  describe "Associations" do
    it { should belong_to(:facility).optional }
    it { should belong_to(:patient).optional }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
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
