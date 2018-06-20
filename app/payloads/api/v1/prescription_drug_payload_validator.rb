class Api::V1::PrescriptionDrugPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :name,
    :dosage,
    :rxnorm_code,
    :is_deleted,
    :is_protocol_drug,
    :patient_id,
    :facility_id,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.prescription_drug
  end
end