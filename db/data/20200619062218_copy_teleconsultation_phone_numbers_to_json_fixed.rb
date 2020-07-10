class CopyTeleconsultationPhoneNumbersToJsonFixed < ActiveRecord::Migration[5.2]
  def up
    Facility.find_each do |facility|
      next if facility.teleconsultation_phone_number.blank? || facility.teleconsultation_isd_code.blank?

      facility.teleconsultation_phone_numbers = [{isd_code: facility.teleconsultation_isd_code,
                                                  phone_number: facility.teleconsultation_phone_number}]
      facility.save
    end
  end

  def down
    Facility.find_each do |facility|
      facility.teleconsultation_phone_numbers = []
      facility.save
    end
  end
end
