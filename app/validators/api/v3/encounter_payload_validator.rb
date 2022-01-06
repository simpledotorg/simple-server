# frozen_string_literal: true

class Api::V3::EncounterPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :patient_id,
    :created_at,
    :updated_at,
    :deleted_at,
    :notes,
    :encountered_on,
    :observations
  )

  validate :validate_schema
  validate :observables_belong_to_single_facility

  def schema
    Api::V3::Models.encounter
  end

  def observables_belong_to_single_facility
    observation_facility_ids = observations.values.flatten.map { |r| r[:facility_id] }.uniq
    if observation_facility_ids.count > 1
      errors.add(:schema, "Encounter observations belong to more than one facility")
    end
  end
end
