require "fhir_models"

class OneOff::Fhir::EncounterExporter
  attr_reader :encounter

  def initialize(encounter)
    @encounter = encounter
  end

  def export
    FHIR::Encounter.new(
      meta: FHIR::Meta.new(
        lastUpdated: patient.device_updated_at.iso8601,
        createdAt: patient.recorded_at.iso8601
      ),
      status: encounter_status,
      identifier: nil,
      class: nil,
      type: nil,
      serviceType: nil,
      subject: nil,
      appointment: nil,
      period: nil,
      reasonCode: nil,
      diagnosis: nil,
      location: nil,
      serviceProvider: nil,
      partOf: nil
    )
  end

  def encounter_status
  end

  def patient_identifiers
    identifiers = [
      FHIR::Identifier.new(
        value: patient.id,
        use: "official"
      )
    ]
    patient.business_identifiers.simple_bp_passport.each do |identifier|
      identifiers << FHIR::Identifier.new(
        value: identifier.identifier,
        use: "secondary"
      )
    end
    identifiers
  end

  def gender
    return "other" unless ["male", "female"].include?(patient.gender)

    patient.gender
  end

  def birth_date
    return patient.age_updated_at - patient.age.years unless patient.date_of_birth

    patient.date_of_birth
  end
end
