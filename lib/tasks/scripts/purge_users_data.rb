# frozen_string_literal: true

module PurgeUsersData
  def self.perform
    abort "Can't run this task in #{ENV["SIMPLE_SERVER_ENV"]}!'" if ENV["SIMPLE_SERVER_ENV"] == "production"

    # These are in a "valid" order so that we don't run into Foreign-Key violations
    models = [BloodPressure,
      BloodSugar,
      Notification,
      Experimentation::TreatmentGroupMembership,
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
    time = Benchmark.ms {
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("truncate #{tables}")
      end
    }
    puts "Truncated Patient related tables in #{time.round} ms"
  end
end
