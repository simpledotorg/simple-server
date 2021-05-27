class CreateReportingPatientStatesPerMonth < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_patient_states_per_month, materialized: true
  end
end
