class OneOff::CPHCEnrollment::BloodPressurePayload
  attr_reader :blood_pressure

  def initialize(blood_pressure)
    @blood_pressure = blood_pressure
  end

  def as_json
    {
      "isVitalsEdited" => true,
      "exam" => {
        "assessDate" => blood_pressure.recorded_at.strftime("%d-%m-%Y"),
        "sys" => blood_pressure.systolic,
        "diast" => blood_pressure.diastolic
      }
    }
  end
end