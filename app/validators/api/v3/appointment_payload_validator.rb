# frozen_string_literal: true

class Api::V3::AppointmentPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :patient_id,
    :facility_id,
    :creation_facility_id,
    :scheduled_date,
    :status,
    :cancel_reason,
    :remind_on,
    :agreed_to_visit,
    :appointment_type,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V3::Models.appointment
  end
end
