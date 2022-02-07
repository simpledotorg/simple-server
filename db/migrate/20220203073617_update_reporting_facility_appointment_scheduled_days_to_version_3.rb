class UpdateReportingFacilityAppointmentScheduledDaysToVersion3 < ActiveRecord::Migration[5.2]
  def change
    drop_view :reporting_facility_states, materialized: true, revert_to_version: 6
    update_view :reporting_facility_appointment_scheduled_days, version: 3, revert_to_version: 1, materialized: true

    create_view :reporting_facility_states, materialized: true, version: 7
    add_index :reporting_facility_states, [:month_date, :facility_region_id], name: :facility_states_month_date_region_id, unique: true
  end
end
