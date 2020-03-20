class Api::V3::BloodPressurePayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :systolic,
    :diastolic,
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
    Api::V3::Models.blood_pressure
  end
end
