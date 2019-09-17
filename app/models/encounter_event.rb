class EncounterEvent < ApplicationRecord
  belongs_to :encounter, optional: true
  belongs_to :user, optional: true

  belongs_to :encounterable, polymorphic: true
end
