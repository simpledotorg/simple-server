require 'csv'
module SoftDeleteDuplicatePatients
  def self.parse(patients_csv_path)
    patients_csv = open(patients_csv_path)
    patients = CSV.parse(patients_csv, headers: true)
    patient_headers = patients.headers

    unless patient_headers.include?('Duplicate?') && patient_headers.include?('Simple Patient ID')
      abort 'Missing columns, Duplicate? and Simple Patient ID must both be present.'
    end

    patients.select { |patient| patient['Duplicate?'] == 'DELETE' }
      .map { |patient| patient['Simple Patient ID'] }
  end

  def self.discard_patient_records(patient)
    patient.address.discard
    patient.medical_history.discard
    patient.phone_numbers.discard_all
    patient.encounters.discard_all
    patient.observations.discard_all
    patient.blood_pressures.discard_all

  end

  def self.discard_patients(patient_ids)
    Patient.where(id: patient_ids).each do |patient|
      discard_patient_records(patient)
    end
  end
end