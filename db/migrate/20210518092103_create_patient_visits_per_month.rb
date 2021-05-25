class CreatePatientVisitsPerMonth < ActiveRecord::Migration[5.2]
  def change
    create_view :patient_visits_per_month, materialized: true
  end
end
