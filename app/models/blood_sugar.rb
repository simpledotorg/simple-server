class BloodSugar < ApplicationRecord
  include Mergeable
  include Observeable

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true
  
  has_one :observation, as: :observable
  has_one :encounter, through: :observation

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  enum blood_sugar_type: {
    random: 'random',
    post_prandial: 'post_prandial',
    fasting: 'fasting'
  }, _prefix: true

end