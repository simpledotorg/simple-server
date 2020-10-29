class DistrictAnalyticsQuery
  include DashboardHelper

  CACHE_VERSION = 2

  attr_reader :region, :facilities

  def initialize(region, period = :month, prev_periods = 3, from_time = Time.current,
    include_current_period: false)

    @period = period
    @prev_periods = prev_periods
    @region = region
    @facilities = @region.facilities
    @district_name = @region.name
    @from_time = from_time
    @include_current_period = include_current_period
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"), force: force_cache?) do
      results
    end
  end

  def results
    results = [
      total_registered_patients,
      registered_patients_by_period,
      follow_up_patients_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end

  def total_registered_patients
    @total_registered_patients ||=
      Patient
        .with_hypertension
        .joins(:registration_facility)
        .where(facilities: {id: facilities})
        .group("facilities.id")
        .count

    return if @total_registered_patients.blank?

    @total_registered_patients
      .map { |facility_id, count| [facility_id, {total_registered_patients: count}] }
      .to_h
  end

  def registered_patients_by_period
    result = ActivityService.new(region, group: [:registration_facility_id]).registrations

    group_by_date_and_facility(result, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    result = ActivityService.new(region, group: BloodPressure.arel_table[:facility_id]).follow_ups

    group_by_date_and_facility(result, :follow_up_patients_by_period)
  end

  private

  def cache_key
    [
      self.class.name,
      facilities.map(&:id).sort,
      @period,
      @prev_periods,
      @from_time.to_s(:mon_year),
      CACHE_VERSION
    ].join("/")
  end

  def group_by_date_and_facility(result, key)
    valid_dates = dates_for_periods(@period,
      @prev_periods,
      from_time: @from_time,
      include_current_period: @include_current_period)

    transformed_result = result.each_with_object({}) { |((date, facility_id), count), hsh|
      next unless date.in?(valid_dates)
      hsh[facility_id] ||= {key => {}}
      hsh[facility_id][key][date] = count
    }

    transformed_result.presence
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
