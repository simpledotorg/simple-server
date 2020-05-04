class BloodPressure < ApplicationRecord
  include Mergeable
  include Hashable
  include Observeable

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at bp_date registration_facility_name user_id
                              bp_systolic bp_diastolic]

  THRESHOLDS = {
    critical: { systolic: 180, diastolic: 110 },
    hypertensive: { systolic: 140, diastolic: 90 }
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
    { id: hash_uuid(id),
      patient_id: hash_uuid(patient_id),
      created_at: created_at,
      bp_date: recorded_at,
      registration_facility_name: facility.name,
      user_id: hash_uuid(user_id),
      bp_systolic: systolic,
      bp_diastolic: diastolic
    }
  end

  #
  # This is a helper class method that is useful for breaking up the BP recording time in various time-periods in SQL.
  # It takes the recorded_at (timestamp without timezone) and truncates it to the beginning of the month.
  #
  # Following is the series of transformations it applies to truncate it in right timezone:
  #
  # * Interpret the "timestamp without timezone" in the DB timezone (UTC).
  # * Converts it to a "timestamp with timezone" the country timezone.
  # * Truncates it to a month (this returns a "timestamp without timezone")
  # * Converts it back to a "timestamp with timezone" in the country timezone
  #
  # FAQ:
  #
  # Q. Why should we cast the truncate into a timestamp with timezone at all? Don't we just end up with day/month?
  # A. DATE_TRUNC returns a "timestamp without timezone" not a month/day/quarter. If it's used in a "where"
  # clause for comparison, the timezone will come into effect and is valuable to be kept correct so as to not run into
  # time-period-boundary issues.
  #
  def self.date_to_period_sql(period)
    tz = Rails.application.config.country[:time_zone]
    "(DATE_TRUNC('#{period}', (blood_pressures.recorded_at::timestamptz) AT TIME ZONE '#{tz}')) AT TIME ZONE '#{tz}'"
  end
end
