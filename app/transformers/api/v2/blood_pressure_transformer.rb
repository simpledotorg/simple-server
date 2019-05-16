class Api::V2::BloodPressureTransformer < Api::Current::Transformer
  class << self
    def to_response(blood_pressure)
      super(blood_pressure).except('recorded_at')
    end

    def from_request(blood_pressure_payload)
      super(blood_pressure_payload).except('recorded_at')
    end
  end
end
