module PatientReportable
  extend ActiveSupport::Concern
  LTFU_PERIOD = 12.months

  included do
    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }

    scope :excluding_dead, -> { where.not(status: :dead) }
    scope :excluding_ltfu, ->(ltfu_as_of: Date.today) do
      where(id: latest_bp_within_ltfu_period(ltfu_as_of).select(:patient_id))
    end

    scope :for_reports, ->(with_exclusions: false, exclude_ltfu_as_of: nil) do
      if with_exclusions
        if exclude_ltfu_as_of
          with_hypertension
            .excluding_dead
            .excluding_ltfu(ltfu_as_of: exclude_ltfu_as_of)
        else
          with_hypertension
            .excluding_dead
        end
      else
        with_hypertension
      end
    end

    def self.latest_bp_within_ltfu_period(ltfu_as_of)
      LatestBloodPressuresPerPatient
        .where("bp_recorded_at > ? AND bp_recorded_at <= ?", ltfu_as_of.to_date - LTFU_PERIOD, ltfu_as_of.to_date)
        .where("patient_recorded_at <= ?", ltfu_as_of.to_date)
    end
  end
end
