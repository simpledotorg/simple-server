module PatientReportable
  extend ActiveSupport::Concern
  LTFU_PERIOD = 12.months

  included do
    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }
    scope :excluding_dead, -> { where.not(status: :dead) }

    scope :ltfu_as_of, ->(date) do
      where.not(id: latest_bps_within_ltfu_period(date).select(:patient_id).distinct)
        .where("recorded_at < ?", date - LTFU_PERIOD)
    end

    scope :not_ltfu_as_of, ->(date) do
      where(id: latest_bps_within_ltfu_period(date).select(:patient_id).distinct)
        .or(where("patients.recorded_at > ?", date - LTFU_PERIOD))
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

    def self.latest_bps_within_ltfu_period(ltfu_as_of)
      LatestBloodPressuresPerPatientPerMonth
        .where("bp_recorded_at > ? AND bp_recorded_at <= ?", ltfu_as_of - LTFU_PERIOD, ltfu_as_of)
    end
  end
end
