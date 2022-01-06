# frozen_string_literal: true

class Api::V3::BloodPressureTransformer < Api::V3::Transformer
  class << self
    def recorded_at(blood_pressure_payload)
      blood_pressure_payload["recorded_at"] || blood_pressure_payload["device_created_at"]
    end

    def from_request(blood_pressure_payload)
      attributes = super(blood_pressure_payload)
      attributes.merge("recorded_at" => recorded_at(attributes))
    end
  end
end
