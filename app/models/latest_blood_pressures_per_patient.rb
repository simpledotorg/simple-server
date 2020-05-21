class LatestBloodPressuresPerPatient < ApplicationRecord
  include BloodPressureable

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  belongs_to :bp_facility, class_name: "Facility", foreign_key: :bp_facility_id
  belongs_to :registration_facility, class_name: "Facility", foreign_key: :registration_facility_id
  belongs_to :patient
end
