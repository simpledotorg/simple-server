# frozen_string_literal: true

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

  THRESHOLDS = {
    high: {random: 300,
           post_prandial: 300,
           fasting: 200,
           hba1c: 9.0}
  }.with_indifferent_access.freeze

  def diabetic?
    blood_sugar_value >= THRESHOLDS[:high][blood_sugar_type]
  end

  def to_s
    "#{blood_sugar_value} #{BLOOD_SUGAR_UNITS[blood_sugar_type]}"
  end
end
