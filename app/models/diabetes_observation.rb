class DiabetesObservation < ApplicationRecord
  include Mergeable

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  enum observation_type: {
    random: 'random',
    post_prandial: 'post_prandial',
    fasting: 'fasting'
  }, _prefix: true

end