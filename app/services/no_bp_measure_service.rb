class NoBPMeasureService
  CACHE_VERSION = 3
  CACHE_TTL = 7.days

  def initialize(region, periods:, with_exclusions: false)
    @region = region
    @periods = periods
    @facilities = region.facilities.to_a
    @facility_ids = @facilities.map(&:id)
    @with_exclusions = with_exclusions
  end

  attr_reader :facilities
  attr_reader :facility_ids
  attr_reader :periods
  attr_reader :region
  attr_reader :with_exclusions

  delegate :cache, to: Rails
  delegate :sanitize_sql, to: ActiveRecord::Base

  def call
    keys = cache_keys_for_period.keys
    cached_results = cache.fetch_multi(*keys, version: cache_version, expires_in: CACHE_TTL, force: force_cache?) { |key|
      period = cache_keys_for_period.fetch(key)
      execute_sql(period)
    }
    cached_results.each_with_object(Hash.new(0)) do |(key, result), hsh|
      period = cache_keys_for_period.fetch(key)
      hsh[period] = result
    end
  end

  def cache_keys_for_period
    @cache_keys_for_period ||= periods.each_with_object({}) { |period, hsh| hsh[cache_key(period)] = period }
  end

  def execute_sql(period)
    return 0 if facility_ids.blank?
    start_date = period.blood_pressure_control_range.begin
    end_date = period.blood_pressure_control_range.end
    registration_date = period.blood_pressure_control_range.begin

    Patient
      .for_reports(with_exclusions: with_exclusions, exclude_ltfu_as_of: period.start_date)
      .joins(sanitize_sql(["LEFT OUTER JOIN appointments ON appointments.patient_id = patients.id
          AND appointments.device_created_at > ?
          AND appointments.device_created_at <= ?", start_date, end_date]))
      .joins(sanitize_sql(["LEFT OUTER JOIN prescription_drugs ON prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at > ?
          AND prescription_drugs.device_created_at <= ?", start_date, end_date]))
      .joins(sanitize_sql(["LEFT OUTER JOIN blood_sugars ON blood_sugars.patient_id = patients.id
          AND blood_sugars.recorded_at > ?
          AND blood_sugars.recorded_at <= ?", start_date, end_date]))
      .where(assigned_facility_id: facility_ids)
      .where("patients.recorded_at <= ?", registration_date)
      .where("appointments.id IS NOT NULL
                OR prescription_drugs.id IS NOT NULL
                OR blood_sugars.id IS NOT NULL")
      .where("NOT EXISTS
                 (SELECT 1
                  FROM blood_pressures bps
                  WHERE patients.id = bps.patient_id
                  AND bps.recorded_at > ?
                  AND bps.recorded_at <= ?)", start_date, end_date)
      .distinct("patients.id")
      .count
  end

  def cache_key(period)
    if with_exclusions
      "#{self.class}/#{region.cache_key}/#{period}/with_exclusions"
    else
      "#{self.class}/#{region.cache_key}/#{period}"
    end
  end

  def cache_version
    "#{region.cache_version}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
