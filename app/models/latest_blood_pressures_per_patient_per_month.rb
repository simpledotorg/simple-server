class LatestBloodPressuresPerPatientPerMonth < ApplicationRecord
  include BloodPressureable
  include PatientReportable

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  belongs_to :patient
  belongs_to :medical_history, primary_key: :patient_id, foreign_key: :patient_id
  belongs_to :facility, class_name: "Facility", foreign_key: "bp_facility_id"

  scope :with_hypertension, -> { where("medical_history_hypertension = ?", "yes") }
  scope :excluding_dead, -> { where.not(patient_status: :dead) }

  scope :ltfu_as_of, ->(date) do
    where.not("bp_recorded_at > ? AND bp_recorded_at <= ?", date.to_date - LTFU_PERIOD, date.to_date)
      .where("patient_recorded_at < ?", date - LTFU_PERIOD)
  end

  scope :not_ltfu_as_of, ->(date) do
    where("bp_recorded_at > ? AND bp_recorded_at <= ?", date.to_date - LTFU_PERIOD, date.to_date)
  end
end
