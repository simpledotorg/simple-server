class LatestBloodPressuresPerPatientPerQuarter < ApplicationRecord
  include BloodPressureable
  scope :with_hypertension, -> { where("medical_history_hypertension = ?", "yes") }

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  belongs_to :patient
end
