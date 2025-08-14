class Api::V3::MedicalHistoryPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :patient_id,
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :receiving_treatment_for_diabetes,
    :diabetes,
    :hypertension,
    :diagnosed_with_hypertension,
    :smoking,
    :smokeless_tobacco,
    :cholesterol,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V3::Models.medical_history
  end
end
