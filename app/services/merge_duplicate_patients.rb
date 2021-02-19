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
      new_patient = create_patient
      create_prescription_drugs(new_patient)
      # mark the other patients merged and soft deleted
      new_patient
    end
  end

  def mark_as_merged
    nil
  end

  def create_patient
    Patient.create(
      id: SecureRandom.uuid,
      recorded_at: earliest_patient.recorded_at,
      registration_facility: earliest_patient.registration_facility,
      registration_user: earliest_patient.registration_user,
      device_created_at: earliest_patient.device_created_at,
      device_updated_at: earliest_patient.device_updated_at,
      assigned_facility: latest_patient.assigned_facility
    )
  end

  def create_prescription_drugs(patient)
    all_prescription_drugs = PrescriptionDrug.where(patient_id: @patients)
    all_prescription_drugs = (all_prescription_drugs.all - latest_patient.prescribed_drugs).each { |pd| pd.is_deleted = true; pd }
    all_prescription_drugs += latest_patient.prescribed_drugs

    all_prescription_drugs.map do |prescription_drug|
      PrescriptionDrug.create(prescription_drug.attributes.merge(
        id: SecureRandom.uuid,
        patient_id: patient.id
      ))
    end
  end
end