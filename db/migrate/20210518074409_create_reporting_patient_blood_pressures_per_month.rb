class CreateReportingPatientBloodPressuresPerMonth < ActiveRecord::Migration[5.2]
  def change
    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"
    create_view :reporting_patient_blood_pressures_per_month, materialized: true
  end
end
