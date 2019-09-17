class Api::Current::EncounterTransformer
  class << self
    def from_nested_request(payload_attributes)
      blood_pressures = payload_attributes[:observations][:blood_pressures]
      blood_pressures_attributes = blood_pressures.map do |blood_pressure|
        Api::Current::BloodPressureTransformer.from_request(blood_pressure)
      end if blood_pressures.present?

      prescription_drugs = payload_attributes[:observations][:prescription_drugs]
      prescription_drugs_attributes = prescription_drugs.map do |prescription_drug|
        Api::Current::Transformer.from_request(prescription_drug)
      end if prescription_drugs.present?

      encounter_attributes = Api::Current::Transformer.from_request(payload_attributes)

      encounter_attributes
        .merge(observations: {
          blood_pressures: blood_pressures_attributes,
          prescription_drugs: prescription_drugs_attributes
        }).with_indifferent_access
    end

    def to_response(_)
    end
  end
end
