class Api::V1::MedicalHistoryPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :patient_id,
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :diabetes,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.medical_history
  end
end
