module PurgeUsersData
  def self.perform
    return "Can't run this task in #{ENV['SIMPLE_SERVER_ENV']}!'" if ENV['SIMPLE_SERVER_ENV'] == 'production'

    # These are in a "valid" order so that we don't run into Foreign-Key violations
    models = [BloodPressure,
              BloodSugar,
              Appointment,
              CallLog,
              Communication,
              PrescriptionDrug,
              Observation,
              Encounter,
              ExotelPhoneNumberDetail,
              TwilioSmsDeliveryDetail,
              MedicalHistory,
              PatientBusinessIdentifier,
              PatientPhoneNumber,
              Patient,
              Address]

    ActiveRecord::Base.transaction do
      models.each do |model|
        puts "Deleting #{model} data"
        model.delete_all
      end
    end
  end
end
