class Questionnaire < ApplicationRecord
  self.primary_key = "version_id"
  belongs_to :questionnaire_version, foreign_key: "version_id"

  delegate :localized_layout, :id, :layout, to: :questionnaire_version

  enum questionnaire_type: {
    monthly_screening_reports: "monthly_screening_reports"
  }

  validates :dsl_version, uniqueness: {
    scope: :questionnaire_type,
    message: "has already been taken for given questionnaire_type"
  }

  scope :for_sync, -> { with_discarded.includes(:questionnaire_version) }
end
