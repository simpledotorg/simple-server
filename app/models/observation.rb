class Observation < ApplicationRecord
  belongs_to :encounter, optional: true
  belongs_to :user, optional: true

  belongs_to :observable, polymorphic: true
end
