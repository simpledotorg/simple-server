module PurgeUsersData
  def self.perform
    return if ENV['SIMPLE_SERVER_ENV'] == 'production'

    models = [BloodPressure, BloodSugar, Appointment, CallLog, Communication, PrescriptionDrug,
              Observation, Encounter, ExotelPhoneNumberDetail, TwilioSmsDeliveryDetail, MedicalHistory,
              PatientBusinessIdentifier, PatientPhoneNumber, Patient, Address]

    ActiveRecord::Base.transaction do
      models.each do |model|
        puts "Deleting #{model} data"
        model.delete_all
      end
    end
  end
end
