module PatientReportable
  extend ActiveSupport::Concern

  included do
    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }

    scope :excluding_dead, -> { where.not(status: :dead) }
    scope :excluding_transferred, -> { where.not(status: :migrated) }

    scope :for_reports, ->(with_exclusions: false) do
      if with_exclusions
        with_hypertension
          .excluding_dead
          .excluding_transferred
      else
        with_hypertension
      end
    end
  end
end
