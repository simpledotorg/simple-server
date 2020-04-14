class Api::V2::BloodPressurePayloadValidator < Api::V3::BloodPressurePayloadValidator
  attr_accessor(
    :id,
    :systolic,
    :diastolic,
    :patient_id,
    :facility_id,
    :user_id,
    :created_at,
    :updated_at,
    :deleted_at
  )

  validate :validate_schema

  def schema
    Api::V2::Models.blood_pressure
  end
end
