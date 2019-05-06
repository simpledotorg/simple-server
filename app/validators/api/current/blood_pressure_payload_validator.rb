class Api::Current::BloodPressurePayloadValidator < Api::Current::PayloadValidator

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
    Api::Current::Models.blood_pressure
  end
end
