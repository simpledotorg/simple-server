# frozen_string_literal: true

class Api::V3::EncounterTransformer
  class << self
    def from_nested_request(payload_attributes)
      blood_pressures = payload_attributes[:observations][:blood_pressures]
      blood_pressures_attributes = if blood_pressures.present?
        blood_pressures.map { |blood_pressure|
          Api::V3::BloodPressureTransformer.from_request(blood_pressure)
        }
      else
        []
      end

      encounter_attributes = Api::V3::Transformer.from_request(payload_attributes)

      encounter_attributes
        .merge(observations: {
          blood_pressures: blood_pressures_attributes
        }).with_indifferent_access
    end

    def to_response(encounter)
      Api::V3::Transformer.to_response(encounter)
        .merge(
          "observations" => {
            "blood_pressures" =>
              encounter.blood_pressures.map { |blood_pressure|
                Api::V3::BloodPressureTransformer.to_response(blood_pressure)
              }
          }
        )
    end
  end
end
