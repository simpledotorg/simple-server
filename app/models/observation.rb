class Observation < ApplicationRecord
  belongs_to :encounter
  belongs_to :user
  belongs_to :observable, polymorphic: true
end
