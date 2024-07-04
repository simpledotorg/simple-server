require "fhir_models"

class OneOff::Fhir::BloodPressureExporter
  attr_reader :blood_pressure

  def initialize(blood_pressure)
    @blood_pressure = blood_pressure
  end

  def export
    FHIR::Observation.new(
      identifier: [
        FHIR::Identifier.new(
          value: blood_pressure.id
        )
      ],
      code: FHIR::CodeableConcept.new(
        coding: FHIR::Coding.new(
          system: "http://loinc.org/",
          code: "85354-9"
        )
      ),
      component: [
        observation_component("8480-6", blood_pressure.systolic),
        observation_component("8462-4", blood_pressure.diastolic)
      ],
      subject: FHIR::Reference.new(
        identifier: FHIR::Identifier.new(
          value: blood_pressure.patient_id
        )
      ),
      meta: FHIR::Meta.new(
        lastUpdated: blood_pressure.device_updated_at.iso8601,
        createdAt: blood_pressure.recorded_at.iso8601
      ),
      performer: FHIR::Reference.new(
        identifier: FHIR::Identifier.new(
          value: blood_pressure.facility_id
        )
      ),
      status: "final"
    )
  end

  def observation_component(code, value)
    FHIR::Observation::Component.new(
      code: FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://loinc.org",
            code: code
          )
        ]
      ),
      valueQuantity: FHIR::Quantity.new(
        value: value,
        unit: "mmHg",
        system: "http://unitsofmeasure.org",
        code: "mm[Hg]"
      )
    )
  end
end
