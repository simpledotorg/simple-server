class DistrictAnalyticsQuery
  include DashboardHelper

  CACHE_VERSION = 1

  attr_reader :facilities

  def initialize(district_name, facilities, period = :month, prev_periods = 3, from_time = Time.current,
    include_current_period: false)

    @period = period
    @prev_periods = prev_periods
    @facilities = facilities
    @district_name = district_name
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
      registered_patients_by_period,
      total_patients,
      total_registered_patients,
      patients_with_bp_by_period,
      follow_up_patients_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end

  def total_registered_patients
    @total_patients ||=
      Patient
        .with_hypertension
        .joins(:registration_facility)
        .where(facilities: {id: facilities})
        .group("facilities.id")
        .count

    return if @total_patients.blank?

    @total_patients
      .map { |facility_id, count| [facility_id, {total_registered_patients: count}] }
      .to_h
  end

  def total_patients
    @total_patients ||=
      Patient
        .with_hypertension
        .joins(:assigned_facility)
        .where(facilities: {id: facilities})
        .group("facilities.id")
        .count

    return if @total_patients.blank?

    @total_patients
      .map { |facility_id, count| [facility_id, {total_patients: count}] }
      .to_h
  end

  def registered_patients_by_period
    @registered_patients_by_period ||=
      Patient
        .with_hypertension
        .joins(:registration_facility)
        .where(facilities: {id: facilities})
        .group("facilities.id")
        .group_by_period(@period, :recorded_at)
        .count

    group_by_facility_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def patients_with_bp_by_period
    @patients_with_bp_by_period ||=
      Patient
        .group("assigned_facility_id")
        .where(assigned_facility: facilities)
        .hypertension_follow_ups_by_period(@period, last: @prev_periods)
        .count

    group_by_facility_and_date(@patients_with_bp_by_period, :patients_with_bp_by_period)
  end

  def follow_up_patients_by_period
    #
    # this is similar to what the group_by_period query already gives us,
    # however, groupdate does not allow us to use these "groups" in a where clause
    # hence, we've replicated its grouping behaviour in order to remove the patients
    # that were registered prior to the period bucket
    #
    date_truncate_string =
      "(DATE_TRUNC('#{@period}', blood_pressures.recorded_at::timestamptz AT TIME ZONE '#{Groupdate.time_zone || 'Etc/UTC'}'))" 

    @follow_up_patients_by_period ||=
      BloodPressure
        .left_outer_joins(:user)
        .left_outer_joins(patient: [:medical_history])
        .joins(:facility)
        .where(facilities: { id: facilities })
        .where(deleted_at: nil)
        .where("medical_histories.hypertension = ?", "yes")
        .group('facilities.id')
        .group_by_period(@period, 'blood_pressures.recorded_at')
        .where("patients.recorded_at < #{date_truncate_string}")
        .order('facilities.id')
        .distinct("recorded_at")
        .count('patients.id')

    group_by_facility_and_date(@follow_up_patients_by_period, :follow_up_patients_by_period)
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

  def group_by_facility_and_date(query_results, key)
    valid_dates = dates_for_periods(@period,
      @prev_periods,
      from_time: @from_time,
      include_current_period: @include_current_period)

    query_results.map { |(facility_id, date), value|
      {facility_id => {key => {date => value}.slice(*valid_dates)}}
    }.inject(&:deep_merge)
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
