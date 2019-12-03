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
  validate :observables_belong_to_single_facility

  def schema
    Api::Current::Models.encounter
  end

  def observables_belong_to_single_facility
    # blood_pressure_facilties = observations[:blood_pressures].map { |r| r[:facility_id] }
    # blood_sugar_facilties = observations[:blood_sugars].map { |r| r[:facility_id] }
    #
    # if (blood_pressure_facilties + blood_sugar_facilties).uniq.count > 1
    #   errors.add(:schema, "Encounter observations belong to more than one facility")
    # end
  end
end
