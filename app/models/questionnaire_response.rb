class QuestionnaireResponse < ApplicationRecord
  belongs_to :questionnaire
  belongs_to :facility
  belongs_to :user

  scope :for_sync, -> { with_discarded }

  #  TODO: do union of 2 `contents`, preferring latest updated_at in case of conflicts.
end
