# frozen_string_literal: true

require "rails_helper"
require "tasks/scripts/soft_delete_duplicate_patients"

RSpec.describe SoftDeleteDuplicatePatients do
  let!(:file_path) { "spec/fixtures/files/patient_de_dup_test.csv" }
  let!(:invalid_file_path) { "spec/fixtures/files/invalid_file_path" }
  let!(:invalid_csv_path) { "spec/fixtures/files/invalid_patient_de_dup_test.csv" }

  context ".parse" do
    it "should fail if you give it a invalid file path" do
      expect { SoftDeleteDuplicatePatients.parse(invalid_file_path) }
        .to raise_error(/No such file or directory/)
    end

    it "should fail if Duplicate? or Simple Patient ID column doesn't exist" do
      allow($stderr).to receive(:write)

      expect { SoftDeleteDuplicatePatients.parse(invalid_csv_path) }
        .to raise_error("Duplicate? and Simple Patient ID columns must both be present.")
    end

    it "should return a filtered set of patients to be soft deleted" do
      expect(SoftDeleteDuplicatePatients.parse(file_path).size).to eq(2)
    end
  end

  context ".discard_patients" do
    let!(:patient_ids) do
      patients_csv = File.open(file_path)
      CSV.parse(patients_csv, headers: true)
        .map { |patient| patient["Simple Patient ID"] }
    end
    let!(:patient_ids_to_delete) { described_class.parse(file_path) }
    let!(:patients) { patient_ids.map { |id| create(:patient, id: id) } }

    it "should discard all patients given their ids" do
      expect { described_class.discard_patients(patient_ids_to_delete) }.to change { Patient.count }.from(5).to(3)
      expect(Patient.unscoped.count).to eq(5)
    end
  end
end
