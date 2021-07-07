class EnhanceReportingSchema < ActiveRecord::Migration[5.2]
  def up
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true
    drop_view :reporting_facilities, materialized: false
    drop_view :reporting_months, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_months, version: 2, materialized: false
    create_view :reporting_facilities, version: 2, materialized: false
    create_view :reporting_patient_blood_pressures_per_month, version: 2, materialized: true
    create_view :reporting_patient_visits_per_month, version: 3, materialized: true
    create_view :reporting_patient_states_per_month, version: 3, materialized: true
  end

  def down
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true
    drop_view :reporting_facilities, materialized: false
    drop_view :reporting_months, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_months, version: 1, materialized: false
    create_view :reporting_facilities, version: 1, materialized: false
    create_view :reporting_patient_blood_pressures_per_month, version: 1, materialized: true
    create_view :reporting_patient_visits_per_month, version: 2, materialized: true
    create_view :reporting_patient_states_per_month, version: 2, materialized: true
  end
end
