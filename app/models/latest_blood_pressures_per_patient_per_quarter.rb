class LatestBloodPressuresPerPatientPerQuarter < ApplicationRecord
  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  belongs_to :patient

  THRESHOLDS = BloodPressure::THRESHOLDS

  scope :hypertensive, (lambda do
    where('systolic >= ? OR diastolic >= ?',
          THRESHOLDS[:hypertensive][:systolic],
          THRESHOLDS[:hypertensive][:diastolic])
  end)

  scope :under_control, (lambda do
    where('systolic < ? AND diastolic < ?',
          THRESHOLDS[:hypertensive][:systolic],
          THRESHOLDS[:hypertensive][:diastolic])
  end)
end
