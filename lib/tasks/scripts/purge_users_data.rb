module PurgeUsersData
  def self.perform
    return if ENV['SIMPLE_SERVER_ENV'] == 'production'

    ActiveRecord::Base.transaction do
      BloodPressure.delete_all
      BloodSugar.delete_all
      Appointment.delete_all
      CallLog.delete_all
      Communication.delete_all
      PrescriptionDrug.delete_all
      Observation.delete_all
      Encounter.delete_all
      ExotelPhoneNumberDetail.delete_all
      TwilioSmsDeliveryDetail.delete_all
      MedicalHistory.delete_all
      PatientBusinessIdentifier.delete_all
      PatientPhoneNumber.delete_all
      Patient.delete_all
      Address.delete_all
    end
  end
end
