class Api::V1::MedicalHistoryPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :patient_id,
    :has_prior_heart_attack,
    :has_prior_stroke,
    :has_chronic_kidney_disease,
    :is_on_treatment_for_hypertension,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.medical_history
  end
end
