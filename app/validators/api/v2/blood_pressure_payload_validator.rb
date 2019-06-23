class Api::V2::BloodPressurePayloadValidator < Api::Current::BloodPressurePayloadValidator
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
