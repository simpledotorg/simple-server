class ReadEncounteredOnInLocalTimeFromDb < ActiveRecord::Migration[5.2]
  def change
    drop_view :reporting_patient_states_per_month, materialized: true
    update_view :reporting_patient_visits_per_month, version: 2, revert_to_version: 1, materialized: true
    create_view :reporting_patient_states_per_month, materialized: true
  end
end
