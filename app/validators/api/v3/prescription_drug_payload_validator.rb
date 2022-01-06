# frozen_string_literal: true

class Api::V3::PrescriptionDrugPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :name,
    :dosage,
    :rxnorm_code,
    :is_deleted,
    :is_protocol_drug,
    :patient_id,
    :facility_id,
    :frequency,
    :duration_in_days,
    :teleconsultation_id,
    :created_at,
    :updated_at,
    :deleted_at
  )

  validate :validate_schema

  def schema
    Api::V3::Models.prescription_drug
  end
end
