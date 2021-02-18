class MergeDuplicatePatients
  def initialize
    super
  end

  def merge_patients(patients)
    new_patient = create_new_patient_from(patients)
    # in a tx, do the following
    new_patient.save
    mark_patients_as_merged(patients)
  end

  def create_new_patient_from(patients)
    sorted_patients = patients.sort_by(&:recorded_at)
    earliest_patient = sorted_patients.first
    latest_patient = sorted_patients.last
    Patient.new(
      recorded_at: earliest_patient.recorded_at,
      registration_facility: earliest_patient.registration_facility,
      registration_user: earliest_patient.registration_user,
      device_created_at: earliest_patient.device_created_at,
      device_updated_at: earliest_patient.device_updated_at,
      assigned_facility: latest_patient.assigned_facility
    )
  end

  def mark_patients_as_merged(patients)
    nil
  end
end