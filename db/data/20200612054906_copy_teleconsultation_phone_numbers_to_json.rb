class CopyTeleconsultationPhoneNumbersToJson < ActiveRecord::Migration[5.2]
  def up
    Facility.where(enable_teleconsultation: true).each do |facility|
      facility.teleconsultation_phone_numbers = [{'isd_code' => facility.teleconsultation_isd_code,
                                                  'phone_number' => facility.teleconsultation_phone_number}]
      facility.save
    end
  end

  def down
    Rails.logger.info "This data migration cannot be reversed. Skipping."
  end
end
