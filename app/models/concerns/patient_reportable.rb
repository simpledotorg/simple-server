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

    # exclude_ltfu_as_of is the Date/Time at which patients are to be considered as LTFU.
    # LTFU patients will be included if this is not passed.
    scope :for_reports, ->(with_exclusions: false, exclude_ltfu_as_of: Time.new(0)) do
      if with_exclusions
        with_hypertension
          .excluding_dead
          .excluding_ltfu(ltfu_as_of: exclude_ltfu_as_of)
      else
        with_hypertension
      end
    end

    def self.latest_bp_within_ltfu_period(ltfu_as_of)
      LatestBloodPressuresPerPatient
        .where("bp_recorded_at > ? AND bp_recorded_at <= ?", ltfu_as_of - LTFU_PERIOD, ltfu_as_of)
        .where("patient_recorded_at <= ?", ltfu_as_of)
    end
  end
end
