class Encounter < ApplicationRecord
  include Mergeable

  belongs_to :patient, optional: true
  belongs_to :facility

  has_many :observations
  has_many :blood_sugars, through: :observations, source: :observable, source_type: 'BloodSugar'
  has_many :blood_pressures, through: :observations, source: :observable, source_type: 'BloodPressure'

  scope :blood_sugars,
        -> { joins(:observations).merge(Observation.blood_pressures) }
  scope :blood_pressures,
        -> { joins(:observations).merge(Observation.blood_pressures) }

  def self.generate_id(facility_id, patient_id, encountered_on)
    UUIDTools::UUID
      .sha1_create(UUIDTools::UUID_DNS_NAMESPACE,
                   [facility_id, patient_id, encountered_on].join(""))
      .to_s
  end

  def self.generate_encountered_on(time, timezone_offset)
    time
      .to_time
      .utc
      .advance(seconds: timezone_offset)
      .to_date
  end

  def self.date_to_period_sql(period)
    tz = Rails.application.config.country[:time_zone]
    "(DATE_TRUNC('#{period}', (encounters_patients_join.encountered_on::timestamptz) AT TIME ZONE '#{tz}')) AT TIME ZONE '#{tz}'"
  end
end
