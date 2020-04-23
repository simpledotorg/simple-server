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
    fasting: 'fasting',
    hba1c: 'hba1c'
  }, _prefix: true

  V3_TYPES = %i[random post_prandial fasting].freeze

  scope :for_v3, -> { where(blood_sugar_type: V3_TYPES) }

  THRESHOLDS = {
    high: { random: 300,
            post_prandial: 300,
            fasting: 200,
            hba1c: 9.0 }
   }.with_indifferent_access.freeze

  def diabetic?
    blood_sugar_value >= THRESHOLDS[:high][blood_sugar_type]
  end

  def self.date_to_period_sql(period)
    tz = Rails.application.config.country[:time_zone]
    "(DATE_TRUNC('#{period}', (blood_sugars.recorded_at::timestamptz) AT TIME ZONE '#{tz}')) AT TIME ZONE '#{tz}'"
  end
end
