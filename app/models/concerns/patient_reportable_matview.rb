module PatientReportableMatview
  extend ActiveSupport::Concern
  include PatientReportable
  LTFU_TIME = PatientReportable::LTFU_TIME

  included do
    scope :with_hypertension, -> { where("medical_history_hypertension = ?", "yes") }
    scope :excluding_dead, -> { where.not(patient_status: :dead) }
  end
end
