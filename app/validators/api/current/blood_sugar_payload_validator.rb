class Api::Current::BloodSugarPayloadValidator < Api::Current::PayloadValidator
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
    Api::Current::Models.blood_sugar
  end
end
