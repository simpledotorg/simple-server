class BloodPressure < ApplicationRecord
  include Mergeable

  belongs_to :facility, optional: true
  belongs_to :patient, optional: true
  belongs_to :user, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end
