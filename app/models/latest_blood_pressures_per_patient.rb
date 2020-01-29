class LatestBloodPressuresPerPatient < ApplicationRecord
  include BloodPressureable

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  belongs_to :facility, foreign_key: :bp_facility_id
  belongs_to :patient

end
