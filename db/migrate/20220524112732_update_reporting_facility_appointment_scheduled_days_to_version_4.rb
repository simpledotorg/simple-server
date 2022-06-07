class UpdateReportingFacilityAppointmentScheduledDaysToVersion4 < ActiveRecord::Migration[5.2]
  def change
    drop_view :reporting_facility_states, revert_to_version: 8, materialized: true

    update_view :reporting_facility_appointment_scheduled_days, version: 4, revert_to_version: 3, materialized: true

    create_view :reporting_facility_states, version: 9, materialized: true
    add_index :reporting_facility_states, [:month_date, :facility_region_id], name: :index_fs_month_date_region_id, unique: true
  end
end
