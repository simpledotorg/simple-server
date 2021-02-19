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
      create_medical_history(new_patient)
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
    current_prescription_drugs = latest_patient.prescribed_drugs
    old_prescription_drugs =
      PrescriptionDrug
        .where(patient_id: @patients)
        .where.not(id: current_prescription_drugs)

    old_prescription_drugs.each { |pd| pd.is_deleted = true }
    (current_prescription_drugs + old_prescription_drugs).map do |prescription_drug|
      PrescriptionDrug.create(prescription_drug.attributes.merge(
        id: SecureRandom.uuid,
        patient_id: patient.id
      ))
    end
  end

  def create_medical_history(patient)
    medical_histories = MedicalHistory.where(patient_id: @patients).order(:device_updated_at)

    MedicalHistory.create(consolidate_medical_history(medical_histories).merge(
      id: SecureRandom.uuid,
      patient_id: patient.id,
      device_created_at: medical_histories.last.device_created_at,
      device_updated_at: medical_histories.last.device_updated_at,
      user_id: medical_histories.last.user_id
    ))
  end

  def consolidate_medical_history(medical_histories)
    attributes_to_merge = [
      *MedicalHistory::MEDICAL_HISTORY_QUESTIONS,
      :prior_heart_attack_boolean,
      :prior_stroke_boolean,
      :chronic_kidney_disease_boolean,
      :receiving_treatment_for_hypertension_boolean,
      :diabetes_boolean,
      :diagnosed_with_hypertension_boolean,
      :hypertension
    ]
    precedence = {"yes" => 0, true => 1, "no" => 2, false => 3, "unknown" => 4, nil => 5}

    attributes_to_merge.each_with_object({}) do |attribute, merged_attributes|
      merged_attributes[attribute] = medical_histories
        .map { |patient| patient[attribute] }
        .min_by { |value| precedence.fetch(value, precedence.size) }
    end
  end
end
