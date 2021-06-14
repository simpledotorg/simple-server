class DoNotMaterializeReportingFacilities < ActiveRecord::Migration[5.2]
  def up
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true
    drop_view :reporting_facilities, materialized: true

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_facilities, materialized: false
    create_view :reporting_patient_blood_pressures_per_month, materialized: true
    create_view :reporting_patient_visits_per_month, materialized: true
    create_view :reporting_patient_states_per_month, materialized: true
  end

  def down
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true
    drop_view :reporting_facilities, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_facilities, materialized: true
    create_view :reporting_patient_blood_pressures_per_month, materialized: true
    create_view :reporting_patient_visits_per_month, materialized: true
    create_view :reporting_patient_states_per_month, materialized: true
  end
end
