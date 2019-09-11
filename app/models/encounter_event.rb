class EncounterEvent < ApplicationRecord
  belongs_to :encounter
  belongs_to :user

  belongs_to :encountered, polymorphic: true
end
