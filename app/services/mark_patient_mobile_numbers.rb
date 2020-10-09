class MarkPatientMobileNumbers
  def self.call
    new.call
  end

  def call
    return unless ENV["FORCE_MARK_PATIENT_MOBILE_NUMBERS"] == "true"

    eligible_numbers.update_all(phone_type: "mobile")
  end

  def eligible_numbers
    PatientPhoneNumber.where.not(phone_type: "mobile")
  end
end
