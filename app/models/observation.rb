class Observation < ApplicationRecord
  belongs_to :encounter
  belongs_to :user
  belongs_to :observable, polymorphic: true, optional: true

  scope :blood_sugars,
        -> { where(observable_type: 'BloodSugar') }
  scope :blood_pressures,
        -> { where(observable_type: 'BloodPressure') }
end
