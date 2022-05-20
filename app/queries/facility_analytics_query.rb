class FacilityAnalyticsQuery
  include BustCache
  include DashboardHelper

  CACHE_VERSION = 2

  def initialize(facility, period = :month, prev_periods = 3, from_time = Time.current, include_current_period: false)
    @facility = facility
    @period = period
    @prev_periods = prev_periods
    @from_time = from_time
    @include_current_period = include_current_period
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"), force: bust_cache?) do
      results
    end
  end

  def results
    results = [
      registered_patients_by_period,
      total_registered_patients,
      follow_up_patients_by_period,
      bp_measures_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end

  def total_registered_patients
    @total_registered_patients ||=
      @facility
        .registered_hypertension_patients
        .group("registration_user_id")
        .distinct("patients.id")
        .count

    return if @total_registered_patients.blank?

    @total_registered_patients
      .map { |user_id, count| [user_id, {total_registered_patients: count}] }
      .to_h
  end

  def registered_patients_by_period
    result = ActivityService.new(@facility, period: @period, group: [:registration_user_id]).registrations

    group_by_date_and_user(result, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    result = ActivityService.new(@facility, period: @period, group: [BloodPressure.arel_table[:user_id]]).follow_ups

    group_by_date_and_user(result, :follow_up_patients_by_period)
  end

  def bp_measures_by_period
    result = ActivityService.new(@facility, group: [BloodPressure.arel_table[:user_id]]).bp_measures

    group_by_date_and_user(result, :bp_measures_by_period)
  end

  private

  def cache_key
    [
      self.class.name,
      @facility.id,
      @period,
      @prev_periods,
      @from_time.to_s(:mon_year),
      CACHE_VERSION
    ].join("/")
  end

  def group_by_date_and_user(result, key)
    valid_dates = dates_for_periods(@period,
      @prev_periods,
      from_time: @from_time,
      include_current_period: @include_current_period)

    transformed_result = result.each_with_object({}) { |((date, user_id), count), hsh|
      next unless date.in?(valid_dates)
      hsh[user_id] ||= {key => {}}
      hsh[user_id][key][date] = count
    }
    transformed_result.presence
  end
end
