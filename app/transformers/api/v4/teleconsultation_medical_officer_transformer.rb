class Api::V4::TeleconsultationMedicalOfficerTransformer
  class << self
    def to_response(medical_officer)
      medical_officer
        .merge(teleconsultation_phone_number: medical_officer.full_teleconsultation_phone_number)
        .slice(response_fields)
    end
  end

  def response_fields
    %w[id full_name teleconsultation_phone_number]
  end
end
