module PatientReportable
  extend ActiveSupport::Concern
  LTFU_PERIOD = 12.months

  included do
    has_one :materialized_latest_blood_pressure,
      class_name: "LatestBloodPressuresPerPatient",
      foreign_key: :patient_id

    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }

    scope :excluding_dead, -> { where.not(status: :dead) }
    scope :excluding_ltfu, -> {
      joins(:materialized_latest_blood_pressure)
        .where("latest_blood_pressures_per_patients.bp_recorded_at < ?", LTFU_PERIOD.ago)
        .where("latest_blood_pressures_per_patients.patient_recorded_at < ?", LTFU_PERIOD.ago)
    }

    scope :for_reports, ->(with_exclusions: false, excluding_ltfu: true) do
      if with_exclusions
        if excluding_ltfu
          with_hypertension.excluding_dead.excluding_ltfu
        else
          with_hypertension.excluding_dead
        end
      else
        with_hypertension
      end
    end
  end
end
