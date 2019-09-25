class Observation < ApplicationRecord
  belongs_to :encounter
  belongs_to :user, optional: true
  belongs_to :observable, polymorphic: true
end
