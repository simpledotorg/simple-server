module PatientReportable
  extend ActiveSupport::Concern
  LTFU_TIME = 12.months

  included do
    delegate :sanitize_sql, to: ActiveRecord::Base

    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }
    scope :excluding_dead, -> { where.not(status: :dead) }

    scope :ltfu_as_of, ->(date) do
      joins("LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months
             ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id
             AND #{sanitize_sql(["bp_recorded_at > ? AND bp_recorded_at < ?", (date.to_date - LTFU_TIME).end_of_month, date])}")
        .where("bp_recorded_at IS NULL AND patients.recorded_at < ?", (date.to_date - LTFU_TIME).end_of_month)
        .distinct(:patient_id)
    end

    scope :not_ltfu_as_of, ->(date) do
      joins("LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months
             ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id")
        .where("bp_recorded_at > ? AND bp_recorded_at < ? OR patients.recorded_at >= ?",
          ltfu_time_ago(date), date, ltfu_time_ago(date))
        .distinct(:patient_id)
    end

    scope :for_reports, ->(with_exclusions: false, exclude_ltfu_as_of: nil) do
      if with_exclusions
        if exclude_ltfu_as_of
          with_hypertension
            .excluding_dead
            .not_ltfu_as_of(exclude_ltfu_as_of)
        else
          with_hypertension
            .excluding_dead
        end
      else
        with_hypertension
      end
    end

    def ltfu_time_ago(date)
      (date.to_date - LTFU_TIME).end_of_month
    end
  end
end
