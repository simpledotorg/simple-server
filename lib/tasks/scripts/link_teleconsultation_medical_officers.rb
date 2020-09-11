class LinkTeleconsultationMedicalOfficers
  class << self
    def call
      Facility.all.map do |facility|
        facility.teleconsultation_phone_numbers.map do |number|
          medical_officer = find_medical_officer_by_number(number["phone_number"])
          if medical_officer && !facility.teleconsultation_medical_officers.include?(medical_officer)
            facility.teleconsultation_medical_officers << medical_officer
            facility.save!
          end

          medical_officer
        end
      end
    end

    private

    def find_medical_officer_by_number(phone_number)
      PhoneNumberAuthentication.find_by_phone_number(phone_number)&.user ||
        User.find_by_teleconsultation_phone_number(phone_number)
    end
  end
end
