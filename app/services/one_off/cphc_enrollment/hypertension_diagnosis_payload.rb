class OneOff::CPHCEnrollment::HypertensionDiagnosisPayload
  attr_reader :blood_pressure, :encounter_id

  def initialize(blood_pressure, encounter_id)
    @blood_pressure = blood_pressure
    @encounter_id = encounter_id
  end

  def payload_as_json
    medical_history = blood_pressure.patient.medical_history
    {"encounterId" => encounter_id,
     "assessmentDate" => blood_pressure.recorded_at.strftime("%d-%m-%Y"),
     "bloodPressureControl" => blood_pressure.hypertensive? ? "Uncontrolled" : "Controlled",
     "selectedDiagnosis" => medical_history.hypertension ? "CONFIRMED_STAGE_1" : "NAD"}
  end
end
