class DistrictAnalyticsQuery
  include BustCache
  include DashboardHelper

  CACHE_VERSION = 4

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
    @current_period = include_current_period ? Period.current : Period.current.previous
    @range = Range.new(@current_period.advance(months: -prev_periods), @current_period)
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"), force: bust_cache?) do
      results
    end
  end

  def results
    results = [
      total_assigned_patients,
      total_registered_patients,
      registered_patients_by_period,
      follow_up_patients_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end

  def total_assigned_patients
    @total_assigned_patients ||=
      Patient
        .for_reports
        .where(assigned_facility: facilities)
        .group(:assigned_facility_id)
        .count

    return if @total_assigned_patients.blank?

    @total_assigned_patients
      .map { |facility_id, count| [facility_id, {total_assigned_patients: count}] }
      .to_h
  end

  def repository
    @repository ||= Reports::Repository.new(facilities, periods: @range)
  end

  def total_registered_patients
    @total_registered_patients ||= @facilities.each_with_object({}) { |facility, result|
      result[facility.id] = {
        total_registered_patients: repository.cumulative_registrations.dig(facility.region.slug, @current_period)
      }
    }
  end

  def period_to_dates(hsh)
    return unless hsh
    hsh.transform_keys { |k| k.to_date }
  end

  def registered_patients_by_period
    @facilities.each_with_object({}) { |facility, result|
      counts = period_to_dates(repository.monthly_registrations[facility.region.slug])
      next unless counts&.any?

      result[facility.id] = {registered_patients_by_period: counts}
    }
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
      d valid_dates

    transformed_result = result.each_with_object({}) { |((date, facility_id), count), hsh|
      next unless date.in?(valid_dates)
      hsh[facility_id] ||= {key => {}}
      hsh[facility_id][key][date] = count
    }

    transformed_result.presence
  end
end
