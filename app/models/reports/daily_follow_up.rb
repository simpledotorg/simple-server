module Reports
  class DailyFollowUp < Reports::View
    self.table_name = "reporting_daily_follow_ups"

    belongs_to :facility, class_name: "::Facility"
    belongs_to :patient

    scope :with_diabetes, -> { where(diabetes: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes]) }
    scope :with_hypertension, -> { where(hypertension: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes]) }
    scope :with_diabetes_only, -> { where(diabetes: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes], hypertension: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no]) }
    scope :with_hypertension_only, -> { where(hypertension: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes], diabetes: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no]) }
    scope :with_hypertension_and_diabetes, -> { where(hypertension: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes], diabetes: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes]) }

    enum patient_gender: {
      female: "female",
      male: "male",
      transgender: "transgender"
    }

    def self.materialized?
      true
    end
  end
end
