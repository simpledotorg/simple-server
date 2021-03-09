class TeleconsultationMedicalOfficer < User
  default_scope { joins(:teleconsultation_facilities).distinct }
end
