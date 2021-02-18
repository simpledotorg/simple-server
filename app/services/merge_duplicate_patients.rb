class MergeDuplicatePatients
  def initialize(patients)
    @patients = patients.sort_by(&:recorded_at)
  end

  def earliest_patient
    @patients.first
  end

  def latest_patient
    @patients.last
  end

  def merge
    ActiveRecord::Base.transaction do
      new_patient = build_patient
      new_patient.save
      prescription_drugs = build_prescription_drugs(new_patient)
      # in a tx, do the following
      new_patient.save
    end
  end

  def mark_as_merged
    nil
  end

  def build_patient
    Patient.new(
      id: SecureRandom.uuid,
      recorded_at: earliest_patient.recorded_at,
      registration_facility: earliest_patient.registration_facility,
      registration_user: earliest_patient.registration_user,
      device_created_at: earliest_patient.device_created_at,
      device_updated_at: earliest_patient.device_updated_at,
      assigned_facility: latest_patient.assigned_facility
    )
  end

  def build_prescription_drugs(patient)
    @patients.map(&:prescription_drugs).flatten.map do |prescription_drug|
      PrescriptionDrug.new(prescription_drug.attributes.merge(patient_id: patient))
    end
  end
end