module PatientReportable
  extend ActiveSupport::Concern
  LTFU_TIME = 12.months

  included do
    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }
    scope :excluding_dead, -> { where.not(status: :dead) }

    scope :ltfu_as_of, ->(date) do
      joins("LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id")
        .where("NOT (bp_recorded_at > ? AND bp_recorded_at < ?) OR bp_recorded_at IS NULL", date - LTFU_TIME, date)
        .where("recorded_at < ?", date - LTFU_TIME)
    end

    scope :not_ltfu_as_of, ->(date) do
      joins("LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id")
        .where("bp_recorded_at > ? AND bp_recorded_at < ? OR patients.recorded_at >= ?", date - LTFU_TIME, date, date - LTFU_TIME)
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
  end
end
