class Api::Current::BloodPressureTransformer < Api::Current::Transformer
  class << self
    def recorded_at(blood_pressure_payload)
      blood_pressure_payload['recorded_at'] || blood_pressure_payload['device_created_at']
    end

    def from_request(blood_pressure_payload)
      super(blood_pressure_payload)
        .merge('recorded_at' => recorded_at(blood_pressure_payload))
    end
  end
end
