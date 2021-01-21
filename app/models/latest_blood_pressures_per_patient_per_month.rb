class LatestBloodPressuresPerPatientPerMonth < ApplicationRecord
  include BloodPressureable

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  belongs_to :patient
  belongs_to :medical_history, primary_key: :patient_id, foreign_key: :patient_id
  belongs_to :facility, class_name: "Facility", foreign_key: "bp_facility_id"

  scope :with_hypertension, -> { where("medical_history_hypertension = ?", "yes") }
end
