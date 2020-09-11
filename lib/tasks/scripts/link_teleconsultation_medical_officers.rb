class LinkTeleconsultationMedicalOfficers
  class << self
    def call
      linked_users_count, unlinked_numbers_count = 0, 0

      Facility.find_each do |facility|
        facility.teleconsultation_phone_numbers.each do |number|
          medical_officer = find_medical_officer_by_number(number["phone_number"])
          if medical_officer
            linked_users_count += 1 if link_medical_officer(medical_officer, facility)
          else
            unlinked_numbers_count += 1
          end
        end
      end

      Rails.logger.info "Linked #{linked_users_count} new medical officers."
      Rails.logger.info "Could not find a match for #{unlinked_numbers_count} numbers."
    end

    private

    def link_medical_officer(medical_officer, facility)
      unless facility.teleconsultation_medical_officers.include?(medical_officer)
        facility.teleconsultation_medical_officers << medical_officer

        Rails.logger.info "Linked #{medical_officer.id} to #{facility.name}"
        facility.save!
      end
    end

    def find_medical_officer_by_number(phone_number)
      PhoneNumberAuthentication.find_by_phone_number(phone_number)&.user ||
        User.find_by_teleconsultation_phone_number(phone_number)
    end
  end
end
