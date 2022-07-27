class CPHCEnrollment::MedicalHistoryPayload
  attr_reader :medical_history

  def initialize(medical_history)
    @medical_history = medical_history
  end

  def as_json
    {
      "assesDate": medical_history.device_created_at.strftime("%d-%m-%Y"),
      "diabts": medical_history.diabetes == "yes",
      "hypertsn": medical_history.hypertension == "yes",
      "heartAtck": medical_history.prior_heart_attack == "yes",
      "strk": medical_history.prior_stroke == "yes",
      "hypertensionReportVerified": medical_history.diagnosed_with_hypertension == "yes"
    }
  end
end
