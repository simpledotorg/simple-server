class CreatePatientRegistrationsPerDayPerFacilities < ActiveRecord::Migration[5.1]
  def change
    create_view :patient_registrations_per_day_per_facilities, materialized: true
  end
end
