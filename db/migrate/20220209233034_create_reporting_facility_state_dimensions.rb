class CreateReportingFacilityStateDimensions < ActiveRecord::Migration[5.2]
  # Renaming the view to better match that is reporting on facility state 'dimensions',
  # i.e. breakdowns by diagnosis and gender
  def change
    drop_view :reporting_facility_state_groups, revert_to_version: 4, materialized: true
    create_view :reporting_facility_state_dimensions, materialized: true
    add_index :reporting_facility_state_dimensions, [:month_date, :facility_region_id], name: :fs_dimensions_month_date_facility_region_id, unique: true
  end
end
