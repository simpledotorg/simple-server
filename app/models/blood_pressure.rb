# frozen_string_literal: true

class BloodPressure < ApplicationRecord
  include Mergeable
  include Hashable
  include Observeable
  extend SQLHelpers

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at bp_date registration_facility_name user_id
    bp_systolic bp_diastolic]

  THRESHOLDS = {
    critical: {systolic: 180, diastolic: 110},
    hypertensive: {systolic: 140, diastolic: 90}
  }.freeze

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true

  has_one :observation, as: :observable
  has_one :encounter, through: :observation

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  scope :hypertensive, -> {
    where(arel_table[:systolic].gteq(THRESHOLDS[:hypertensive][:systolic]))
      .or(where(arel_table[:diastolic].gteq(THRESHOLDS[:hypertensive][:diastolic])))
  }

  scope :under_control, -> {
    where(arel_table[:systolic].lt(THRESHOLDS[:hypertensive][:systolic]))
      .where(arel_table[:diastolic].lt(THRESHOLDS[:hypertensive][:diastolic]))
  }

  scope :for_sync, -> { with_discarded }

  scope :for_recent_bp_log, -> do
    recorded_date = "DATE(recorded_at at time zone 'UTC' at time zone '#{CountryConfig.current[:time_zone]}')"
    order(Arel.sql("#{recorded_date} DESC, recorded_at ASC"))
  end

  def critical?
    systolic >= THRESHOLDS[:critical][:systolic] || diastolic >= THRESHOLDS[:critical][:diastolic]
  end

  def hypertensive?
    systolic >= THRESHOLDS[:hypertensive][:systolic] || diastolic >= THRESHOLDS[:hypertensive][:diastolic]
  end

  def under_control?
    !hypertensive?
  end

  def recorded_days_ago
    (Date.current - device_created_at.to_date).to_i
  end

  def to_s
    [systolic, diastolic].join("/")
  end

  def anonymized_data
    {id: hash_uuid(id),
     patient_id: hash_uuid(patient_id),
     created_at: created_at,
     bp_date: recorded_at,
     registration_facility_name: facility.name,
     user_id: hash_uuid(user_id),
     bp_systolic: systolic,
     bp_diastolic: diastolic}
  end
end
