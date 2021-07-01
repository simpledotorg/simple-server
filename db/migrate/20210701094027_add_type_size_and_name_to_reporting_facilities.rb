class AddTypeSizeAndNameToReportingFacilities < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facilities, version: 2, revert_to_version: 1, materialized: false
  end

  def up
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    update_view :reporting_facilities, version: 2, revert_to_version: 1, materialized: false
    create_view :reporting_patient_blood_pressures_per_month, materialized: true
    create_view :reporting_patient_visits_per_month, version: 2, revert_to_version: 1, materialized: true
    create_view :reporting_patient_states_per_month, version: 2, revert_to_version: 1, materialized: true
  end

  def down
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true
    drop_view :reporting_facilities, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create :reporting_facilities, materialized: false
    create_view :reporting_patient_blood_pressures_per_month, materialized: true
    create_view :reporting_patient_visits_per_month, version: 2, revert_to_version: 1, materialized: true
    create_view :reporting_patient_states_per_month, version: 2, revert_to_version: 1, materialized: true
  end
end
