require 'rails_helper'
require 'tasks/scripts/soft_delete_duplicate_patients'

RSpec.describe SoftDeleteDuplicatePatients do
  let!(:file_path) { 'spec/fixtures/files/patient_de_dup_test.csv' }
  let!(:invalid_file_path) { 'spec/fixtures/files/invalid_file_path' }
  let!(:invalid_csv_path) { 'spec/fixtures/files/invalid_patient_de_dup_test.csv' }

  context '.parse' do
    it 'should fail if you give it a invalid file path' do
      expect { SoftDeleteDuplicatePatients.parse(invalid_file_path) }
        .to raise_error(/No such file or directory/)
    end

    it "should fail if Duplicate? or Simple Patient ID column doesn't exist" do
      expect { SoftDeleteDuplicatePatients.parse(invalid_csv_path) }
        .to raise_error('Missing columns, Duplicate? and Simple Patient ID must both be present.')
    end

    it 'should return a filtered set of patients to be soft deleted' do
      expect(SoftDeleteDuplicatePatients.parse(file_path).size).to eq(3)
    end
  end

  context 'Soft delete records' do

    let!(:patient_ids) do
      patients_csv = open(file_path)
      CSV.parse(patients_csv, headers: true)
        .map { |patient| patient['Simple Patient ID'] }
    end
    let!(:patient_ids_to_delete) do
      SoftDeleteDuplicatePatients
        .parse(file_path)
    end
    let!(:patients) do
      patient_ids.map do |id|
        create(:patient, id: id)
      end
    end

    context '.discard_patient_records' do
      it "should soft delete a patient and it's associated records" do
        patient_id = patient_ids_to_delete.first
        patient = Patient.find(patient_id)

        described_class.discard_patient_records(patient)
        expect(patient.address.discarded?).to be true
        expect(Address.find_by(id: patient.address.id)).to be_nil
      end
    end
  end
end