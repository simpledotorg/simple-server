class OneOff::CphcEnrollment::HypertensionExaminationPayload
  def payload
    nil
  end

  def headers
    {"Host" => ENV.fetch("CPHC_HYPERTENSION_HOST")}
  end
end
