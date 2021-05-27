class CreateReportingPatientBloodPressuresPerMonth < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_patient_blood_pressures_per_month, materialized: true
  end
end
