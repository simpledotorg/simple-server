class Api::V1::BloodPressurePayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :systolic,
    :diastolic,
    :patient_id,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Spec.blood_pressure_spec
  end
end