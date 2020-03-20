class Api::V3::BloodSugarPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :blood_sugar_type,
    :blood_sugar_value,
    :patient_id,
    :facility_id,
    :user_id,
    :created_at,
    :updated_at,
    :deleted_at,
    :recorded_at
  )

  validate :validate_schema

  def schema
    Api::V3::Models.blood_sugar
  end
end
