class Api::V4::TeleconsultationPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :patient_id,
    :medical_officer_id,
    :record,
    :request,
    :updated_at,
    :deleted_at,
    :created_at
  )

  validate :validate_schema

  def schema
    Api::V4::Models.teleconsultation
  end
end
