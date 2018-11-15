class Api::Current::BloodPressurePayloadValidator < Api::Current::PayloadValidator

  attr_accessor(
    :id,
    :systolic,
    :diastolic,
    :patient_id,
    :facility_id,
    :user_id,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::Current::Schema::Models.blood_pressure
  end
end
