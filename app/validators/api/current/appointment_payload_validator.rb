class Api::Current::AppointmentPayloadValidator < Api::Current::PayloadValidator

  attr_accessor(
    :id,
    :patient_id,
    :facility_id,
    :scheduled_date,
    :status,
    :cancel_reason,
    :remind_on,
    :agreed_to_visit,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::Current::Models.appointment
  end
end
