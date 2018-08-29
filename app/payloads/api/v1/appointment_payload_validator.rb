class Api::V1::AppointmentPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :patient_id,
    :facility_id,
    :date,
    :status,
    :status_reason,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.appointment
  end
end
