class LatestBloodPressuresPerPatientPerDay < ApplicationRecord
  include BloodPressureable

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  belongs_to :patient
  belongs_to :facility, class_name: "Facility", foreign_key: "bp_facility_id"
end
