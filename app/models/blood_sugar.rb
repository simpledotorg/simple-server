class BloodSugar < ApplicationRecord
  include Mergeable
  include Observeable
  extend SQLHelpers

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true

  has_one :observation, as: :observable
  has_one :encounter, through: :observation

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  enum blood_sugar_type: {
    random: "random",
    post_prandial: "post_prandial",
    fasting: "fasting",
    hba1c: "hba1c"
  }, _prefix: true

  BLOOD_SUGAR_UNITS = {
    random: "mg/dL",
    post_prandial: "mg/dL",
    fasting: "mg/dL",
    hba1c: "%"
  }.with_indifferent_access.freeze

  V3_TYPES = %i[random post_prandial fasting].freeze

  scope :for_v3, -> { where(blood_sugar_type: V3_TYPES) }
  scope :for_sync, -> { with_discarded }
  scope :for_recent_measures_log, -> do
    recorded_date = "DATE(recorded_at at time zone 'UTC' at time zone '#{CountryConfig.current[:time_zone]}')"
    order(Arel.sql("#{recorded_date} DESC, recorded_at ASC"))
  end

  THRESHOLDS = {
    bs_below_200:
      {random: 0..200, post_prandial: 0..200, fasting: 0..126, hba1c: 0..7},
    bs_200_to_300:
      {random: 200..300, post_prandial: 200..300, fasting: 126..200, hba1c: 7..9},
    bs_over_300: {
      random: 300..Float::INFINITY,
      post_prandial: 300..Float::INFINITY,
      fasting: 200..Float::INFINITY,
      hba1c: 9..Float::INFINITY
    }
  }.with_indifferent_access.freeze

  def diabetic?
    blood_sugar_value >= THRESHOLDS[:bs_over_300][blood_sugar_type].first
  end

  def to_s
    "#{blood_sugar_value.round(2)} #{BLOOD_SUGAR_UNITS[blood_sugar_type]}"
  end

  def risk_state
    risk_state = nil
    THRESHOLDS.each do |state, threshold|
      if threshold[blood_sugar_type].include?(blood_sugar_value)
        risk_state = state
        break
      end
    end
    risk_state.to_sym
  end
end
