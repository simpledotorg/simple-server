class Questionnaire < ApplicationRecord
  belongs_to :questionnaire_version, foreign_key: "version_id"

  delegate :localized_layout, :created_at, to: :questionnaire_version

  enum questionnaire_type: {
    monthly_screening_reports: "monthly_screening_reports"
  }

  validates :dsl_version, uniqueness: {
    scope: :questionnaire_type,
    message: "already exists for given questionnaire type"
  }

  scope :for_sync, -> { with_discarded.includes(:questionnaire_version) }
end
