class Api::Current::EncounterPayloadValidator < Api::Current::PayloadValidator
  attr_accessor(
    :id,
    :patient_id,
    :created_at,
    :updated_at,
    :deleted_at,
    :notes,
    :encountered_on,
    :observations,
  )

  validate :validate_schema

  def schema
    Api::Current::Models.encounter
  end
end
