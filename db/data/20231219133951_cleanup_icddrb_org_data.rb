# frozen_string_literal: true

class CleanupIcddrbOrgData < ActiveRecord::Migration[6.1]
  FACILITY_ID = "f472c5db-188f-4563-9bc7-9f86a6ed6403"

  def up
    unless CountryConfig.current_country?("Bangladesh") && ENV["SIMPLE_SERVER_ENV"] == "production"
      return print "CleanupIcddrbFacilityData is only for production Bangladesh"
    end

    ActiveRecord::Base.transaction do
      Appointment.where(facility_id: FACILITY_ID).delete_all
      PrescriptionDrug.where(facility_id: FACILITY_ID).delete_all
      MedicalHistory.joins(:patient).where(patient: {assigned_facility_id: FACILITY_ID}).delete_all
      BloodSugar.where(facility_id: FACILITY_ID).delete_all
      BloodPressure.where(facility_id: FACILITY_ID).delete_all
      Observation.joins(:encounter).where(encounters: {facility_id: FACILITY_ID}).delete_all
      Encounter.where(facility_id: FACILITY_ID).delete_all
      PatientPhoneNumber.joins(:patient).where(patient: {assigned_facility_id: FACILITY_ID}).delete_all
      PatientBusinessIdentifier.joins(:patient).where(patient: {assigned_facility_id: FACILITY_ID}).delete_all
      addresses = Address.joins("JOIN patients ON patients.address_id=addresses.id").where(patients: {assigned_facility_id: FACILITY_ID})
      Patient.where(assigned_facility_id: FACILITY_ID).delete_all
      addresses.delete_all
    end
  end

  def down
    puts "This migration cannot be reversed."
  end
end
