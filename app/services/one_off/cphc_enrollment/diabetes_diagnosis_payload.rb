class OneOff::CPHCEnrollment::DiabetesDiagnosisPayload
  attr_reader :blood_sugar, :encounter_id

  def initialize(blood_sugar, encounter_id)
    @blood_sugar = blood_sugar
    @encounter_id = encounter_id
  end

  def payload
    medical_history = blood_sugar.patient.medical_history
    {"encounterId" => encounter_id,
     "date" => blood_sugar.recorded_at.strftime("%d-%m-%Y"),
     "selectedDiagnosis" => medical_history.diabetes ? "CONFIRMED" : "NAD"}
  end
end
