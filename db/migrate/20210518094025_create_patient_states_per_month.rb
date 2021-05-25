class CreatePatientStatesPerMonth < ActiveRecord::Migration[5.2]
  def change
    create_view :patient_states_per_month, materialized: true
  end
end
