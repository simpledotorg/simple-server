class Api::V4::CallResultPayloadValidator < Api::V4::PayloadValidator
  attr_accessor(
    :id,
    :user_id,
    :appointment_id,
    :patient_id,
    :facility_id,
    :remove_reason,
    :result_type,
    :deleted_at,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V4::Models.call_result
  end
end
