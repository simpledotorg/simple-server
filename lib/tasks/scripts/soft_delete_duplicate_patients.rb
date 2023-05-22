# frozen_string_literal: true

require "csv"
# This module provides two methods:
# parse(csv) will accept a CSV input file and read patient ids to soft-delete
# discard_patients(ids) will soft-delete patients and their associated records
module SoftDeleteDuplicatePatients
  def self.parse(patients_csv_path)
    patients_csv = File.open(patients_csv_path)
    patients = CSV.parse(patients_csv, headers: true)
    patient_headers = patients.headers

    unless patient_headers.include?("Duplicate?") &&
        patient_headers.include?("Simple Patient ID")
      abort "Duplicate? and Simple Patient ID columns must both be present."
    end

    patients
      .select { |patient| patient["Duplicate?"] == "DELETE" }
      .map { |patient| patient["Simple Patient ID"] }
  end

  def self.discard_patients(patient_ids)
    Patient.where(id: patient_ids).map do |p|
      p.discard_data(reason: Patient.deleted_reason[:duplicate])
    end
  end
end
