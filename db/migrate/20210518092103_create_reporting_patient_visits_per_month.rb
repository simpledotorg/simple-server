class CreateReportingPatientVisitsPerMonth < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_patient_visits_per_month, materialized: true
  end
end
