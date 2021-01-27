class LatestBloodPressuresPerPatientPerQuarter < ApplicationRecord
  include BloodPressureable
  include PatientReportable

  belongs_to :patient
  has_one :materialized_latest_blood_pressure,
    class_name: "LatestBloodPressuresPerPatient",
    primary_key: :patient_id,
    foreign_key: :patient_id

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  scope :with_hypertension, -> { where("medical_history_hypertension = ?", "yes") }
  scope :excluding_dead, -> { where.not(patient_status: :dead) }
  scope :excluding_ltfu, ->(ltfu_as_of: Date.today) do
    where(patient_id: latest_bp_within_ltfu_period(ltfu_as_of).select(:patient_id))
  end
end
