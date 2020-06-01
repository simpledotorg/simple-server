class UpdatePatientRegistrationsPerDayPerFacilitiesToVersion2 < ActiveRecord::Migration[5.1]
  def change
    update_view :patient_registrations_per_day_per_facilities,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end
