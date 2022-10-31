class OneOff::CphcEnrollment::DiabetesExaminationPayload
  def payload
    nil
  end

  def headers
    {"Host" => ENV.fetch("CPHC_DIABETES_HOST")}
  end
end
