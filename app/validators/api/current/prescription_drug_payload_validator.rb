class Api::Current::PrescriptionDrugPayloadValidator < Api::Current::PayloadValidator

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
    :updated_at,
    :recorded_at
  )

  validate :validate_schema

  def schema
    Api::Current::Models.prescription_drug
  end
end