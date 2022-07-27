class CPHCEnrollment::MedicalHistoryPayload
  attr_reader :medical_history

  def initialize(medical_history)
    @medical_history = medical_history
  end

  def as_json
    {
      "assesDate": medical_history.recorded_at.strftime("%d-%m-%Y"),
      "diabts": medical_history.diabetes,
      "hypertsn": medical_history.hypertension,
      "heartAtck": medical_history.prior_hearth_attack,
      "strk": medical_history.prior_stroke,
      "diabetesReportVerified": medical_history.diagnosed_with_diabetes,
      "hypertensionReportVerified": medical_history.diagnosed_with_hypertension
    }

  end
end
