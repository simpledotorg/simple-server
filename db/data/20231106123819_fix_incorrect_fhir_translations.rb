# frozen_string_literal: true

class FixIncorrectFhirTranslations < ActiveRecord::Migration[6.1]
  FACILITY_ID = "f472c5db-188f-4563-9bc7-9f86a6ed6403"

  def up
    unless CountryConfig.current_country?("Bangladesh") && ENV["SIMPLE_SERVER_ENV"] == "production"
      return print "FixIncorrectFhirTranslations is only for production Bangladesh"
    end

    patients_from_facility = Patient.where(assigned_facility_id: FACILITY_ID)
    patient_business_identifiers = patients_from_facility.flat_map(&:business_identifiers)
    patient_business_identifiers.each do |identifier|
      resources_to_update = [
        *MedicalHistory.where(patient_id: identifier.id),
        *BloodPressure.where(patient_id: identifier.id),
        *BloodSugar.where(patient_id: identifier.id),
        *PrescriptionDrug.where(patient_id: identifier.id)
      ]

      resources_to_update.each do |resource|
        puts "updating patient ID of #{resource.class.name}:#{resource.id} from #{resource.patient_id} to #{identifier.patient_id}"
        resource.patient_id = identifier.patient_id
        resource.save!
      end
    end
  end

  def down
    puts "FixIncorrectFhirTranslations cannot be reversed."
  end
end
