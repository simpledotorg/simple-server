class Questionnaire < ApplicationRecord
  scope :for_sync, -> { with_discarded }
end
