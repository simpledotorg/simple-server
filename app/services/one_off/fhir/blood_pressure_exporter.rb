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
          value: blood_pressure.id.to_s
        )
      ],
      component: [
        observation_component("8460-6", blood_pressure.systolic),
        observation_component("8460-8", blood_pressure.diastolic),
        FHIR::ObservationComponent.new
      ],
      subject: FHIR::Reference.new(
        reference: FHIR::Patient.new(
          id: blood_pressure.patient_id
        )
      )
    )
  end

  def observation_component(code, value)
    FHIR::ObservationComponent.new(
      code: FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://loinc.org",
            code: code
          )
        ],
        value_quantity: FHIR::Quantity.new(
          value: value,
          unit: "mmHg",
          system: "http://unitsofmeasure.org",
          code: "mm[Hg]"
        )
      )
    )
  end
end
