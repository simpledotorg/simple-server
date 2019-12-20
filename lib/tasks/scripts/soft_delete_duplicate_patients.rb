require 'csv'
module SoftDeleteDuplicatePatients
  def self.parse(patients_csv_path)
    patients_csv = open(patients_csv_path)
    patients = CSV.parse(patients_csv, headers: true)
    patient_headers = patients.headers

    unless patient_headers.include?('Duplicate?') && patient_headers.include?('Simple Patient ID')
      abort 'Missing columns, Duplicate? and Simple Patient ID must both be present.'
    end

    patients
      .select { |patient| patient['Duplicate?'] == 'DELETE' }
      .map { |patient| patient['Simple Patient ID'] }
  end

  def self.discard_patients(patient_ids)
    Patient.where(id: patient_ids).each(&:discard_data)
  end
end