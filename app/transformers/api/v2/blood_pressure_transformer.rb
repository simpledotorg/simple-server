class Api::V2::BloodPressureTransformer < Api::Current::BloodPressureTransformer
  class << self
    def to_response(blood_pressure)
      super(blood_pressure).except('recorded_at')
    end
  end
end
