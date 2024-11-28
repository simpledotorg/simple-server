class Api::V4::PatientAttributePayloadValidator < Api::V4::PayloadValidator
  attr_accessor(
    :id,
    :patient_id,
    :height,
    :weight,
    :height_unit,
    :weight_unit,
    :deleted_at,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V4::Models.patient_attribute
  end
end
