class LinkTeleconsultationMedicalOfficers
  class << self
    def call
      linked_users_count = 0
      unlinked_numbers_count = 0
      already_linked_users_count = 0

      Facility.find_each do |facility|
        facility.teleconsultation_phone_numbers.each do |number|
          phone_number = number["phone_number"]
          medical_officer = find_medical_officer_by_number(phone_number)

          if !medical_officer
            unlinked_numbers_count += 1
          elsif linked?(medical_officer, facility)
            already_linked_users_count += 1
          else
            link_medical_officer(medical_officer, facility)
            linked_users_count += 1
          end
        end
      end

      Rails.logger.info "#{already_linked_users_count} medical officers already linked."
      Rails.logger.info "Linked #{linked_users_count} new medical officers."
      Rails.logger.info "Could not find a match for #{unlinked_numbers_count} numbers."
    end

    private

    def linked?(medical_officer, facility)
      facility.teleconsultation_medical_officers.include?(medical_officer)
    end

    def link_medical_officer(medical_officer, facility)
      facility.teleconsultation_medical_officers << medical_officer

      facility.save!
      Rails.logger.info "Linked User #{medical_officer.id} to #{facility.name}"
    end

    def find_medical_officer_by_number(phone_number)
      PhoneNumberAuthentication.find_by_phone_number(phone_number)&.user ||
        User.find_by_teleconsultation_phone_number(phone_number)
    end
  end
end
