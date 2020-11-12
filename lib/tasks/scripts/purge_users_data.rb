module PurgeUsersData
  def self.perform
    return "Can't run this task in #{ENV["SIMPLE_SERVER_ENV"]}!'" if ENV["SIMPLE_SERVER_ENV"] == "production"

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
      Address,
      Teleconsultation]

    tables = models.map(&:table_name).join(", ")
    time = Benchmark.ms do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("truncate #{tables}")
      end
    end
    puts "Truncated all tables in #{time.round} ms"
  end
end
