class CreatePatientEncountersPerMonth < ActiveRecord::Migration[5.2]
  def change
    create_view :patient_encounters_per_month, materialized: true
  end
end
