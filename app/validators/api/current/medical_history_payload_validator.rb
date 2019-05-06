class Api::Current::MedicalHistoryPayloadValidator < Api::Current::PayloadValidator

  attr_accessor(
    :id,
    :patient_id,
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :diabetes,
    :diagnosed_with_hypertension,
    :created_at,
    :updated_at,
    :recorded_at
  )

  validate :validate_schema

  def schema
    Api::Current::Models.medical_history
  end
end
