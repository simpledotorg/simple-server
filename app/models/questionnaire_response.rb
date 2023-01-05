class QuestionnaireResponse < ApplicationRecord
  belongs_to :questionnaire

  scope :for_sync, -> { with_discarded }

  #  TODO: do union of 2 `contents`, preferring latest updated_at in case of conflicts.
end
