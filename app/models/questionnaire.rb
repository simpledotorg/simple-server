class Questionnaire < ApplicationRecord
  belongs_to :questionnaire_version, foreign_key: "version_id"

  scope :for_sync, -> { with_discarded.includes(:questionnaire_version) }

  delegate :localized_layout, :created_at, to: :questionnaire_version
end
