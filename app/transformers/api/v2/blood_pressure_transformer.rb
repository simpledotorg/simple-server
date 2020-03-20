class Api::V2::BloodPressureTransformer < Api::V3::BloodPressureTransformer
  class << self
    def to_response(blood_pressure)
      super(blood_pressure)
        .except('recorded_at')
    end
  end
end
