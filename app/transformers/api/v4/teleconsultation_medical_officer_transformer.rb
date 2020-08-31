class Api::V4::TeleconsultationMedicalOfficerTransformer
  class << self
    def to_response(medical_officer)
      medical_officer[:teleconsultation_phone_number] = medical_officer.full_teleconsultation_phone_number
      medical_officer.slice("id",
        "full_name",
        "teleconsultation_phone_number")
    end
  end
end
