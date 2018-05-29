class BloodPressure < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true

end
