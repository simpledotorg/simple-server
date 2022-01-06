# frozen_string_literal: true

module PatientReportable
  extend ActiveSupport::Concern
  LTFU_TIME = 12.months

  included do
    delegate :sanitize_sql, to: ActiveRecord::Base

    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }
    scope :excluding_dead, -> { where.not(status: :dead) }

    scope :ltfu_as_of, ->(time) do
      last_bp_after = (time - LTFU_TIME).end_of_month
      joins("LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months
             ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id
             AND #{sanitize_sql(["bp_recorded_at > ? AND bp_recorded_at < ?", last_bp_after, time])}")
        .where("bp_recorded_at IS NULL AND patients.recorded_at <= ?", last_bp_after)
        .distinct(:patient_id)
    end

    scope :not_ltfu_as_of, ->(time) do
      last_bp_after = (time - LTFU_TIME).end_of_month
      joins("LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months
             ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id")
        .where("bp_recorded_at > ? AND bp_recorded_at < ? OR patients.recorded_at >= ?",
          last_bp_after, time, last_bp_after)
        .distinct(:patient_id)
    end

    scope :for_reports, ->(exclude_ltfu_as_of: nil) do
      scope = with_hypertension.excluding_dead

      if exclude_ltfu_as_of
        scope.not_ltfu_as_of(exclude_ltfu_as_of)
      else
        scope
      end
    end
  end
end
