# frozen_string_literal: true

class MyFacilitiesController < AdminController
  include Pagination
  include MyFacilitiesFiltering
  include CohortPeriodSelection
  include PeriodSelection

  DEFAULT_ANALYTICS_TIME_ZONE = "Asia/Kolkata"
  PERIODS_TO_DISPLAY = {quarter: 3, month: 3, day: 14}.freeze

  around_action :set_time_zone
  before_action :set_period, except: [:index]
  before_action :authorize_my_facilities
  before_action :set_selected_cohort_period, only: [:blood_pressure_control]
  before_action :set_selected_period, only: [:registrations, :missed_visits]
  before_action :set_last_updated_at

  attr_reader :numerator

  def index
    @facilities = current_admin.accessible_facilities(:view_reports)
    users = current_admin.accessible_users(:manage)

    @users_requesting_approval = paginate(users
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    overview_query = OverviewQuery.new(facilities: @facilities)
    @inactive_facilities = overview_query.inactive_facilities

    @facility_counts_by_size = {total: @facilities.group(:facility_size).count,
                                inactive: @inactive_facilities.group(:facility_size).count}

    @inactive_facilities_bp_counts =
      {last_week: overview_query.total_bps_in_last_n_days(n: 7),
       last_month: overview_query.total_bps_in_last_n_days(n: 30)}
  end

  def bp_controlled
    facilities = filter_facilities
    @data_for_facility = {}
    @numerator = 'controlled_patients'
    facilities.each do |facility|
      facility_data = Reports::RegionService.new(region: facility, period: @period).call
      add_facility_stats(facility_data)
      @data_for_facility[facility.name] = facility_data
    end
    calculate_control_rate
  end

  def bp_not_controlled
    facilities = filter_facilities
    @data_for_facility = {}
    @numerator = 'uncontrolled_patients'
    facilities.each do |facility|
      facility_data = Reports::RegionService.new(region: facility, period: @period).call
      add_facility_stats(facility_data)
      @data_for_facility[facility.name] = facility_data
    end
    calculate_control_rate
  end

  def missed_visits
    facilities = filter_facilities
    @data_for_facility = {}
    @numerator = 'missed_visits'
    facilities.each do |facility|
      facility_data = Reports::RegionService.new(region: facility, period: @period).call
      add_facility_stats(facility_data)
      @data_for_facility[facility.name] = facility_data
    end
    calculate_control_rate
  end

  private

  def set_last_updated_at
    last_updated_at = RefreshMaterializedViews.last_updated_at
    @last_updated_at =
      if last_updated_at.nil?
        "unknown"
      else
        last_updated_at.in_time_zone(Rails.application.config.country[:time_zone]).strftime("%d-%^b-%Y %I:%M%p")
      end
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end

  def authorize_my_facilities
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def set_period
    @period = Period.month(Date.current.last_month.beginning_of_month)
    @start_period = @period.advance(months: -5)
  end

  def set_force_cache
    RequestStore.store[:force_cache] = true if force_cache?
  end

  def report_params
    params.permit(:id, :force_cache, :report_scope, {period: [:type, :value]})
  end

  def force_cache?
    report_params[:force_cache].present?
  end

  def report_with_exclusions?
    current_admin.feature_enabled?(:report_with_exclusions)
  end

  def add_facility_stats(facility_data)
    size = facility_data.region.facility_size
    add_size_section(size) unless stats_by_size[size]
    months.each do |month|
      current_month = stats_by_size[size][month.to_s]
      current_month[numerator] += find_stat_by_month(facility_data, numerator, month)
      current_month['adjusted_registrations'] += find_stat_by_month(facility_data, 'adjusted_registrations', month)
      current_month['cumulative_registrations'] += find_stat_by_month(facility_data, 'cumulative_registrations', month)
    end
  end

  def calculate_control_rate
    stats_by_size.each_pair do |size, month_data|
      month_numerator = month_data.map{|_, aggregates| aggregates[numerator] }.sum
      month_registratrions = month_data.map{|_, aggregates| aggregates['adjusted_registrations'] }.sum
      rate = (month_registratrions == 0) ? 0 : (month_numerator.to_f / month_registratrions.to_f * 100).round
      stats_by_size[size]['control_rate'] = rate
    end
  end

  def months
    @months ||= @period.downto(5)
  end

  def stats_by_size
      @stats_by_size ||= {}
  end

  def add_size_section(size)
    stats_by_size[size] = size_data_template
  end

  def size_data_template
    months.reduce({}) do |hsh, month|
      hsh[month.to_s] = month_data_template
      hsh
    end
  end

  def month_data_template
    {
      numerator => 0,
      'adjusted_registrations' => 0,
      'cumulative_registrations' => 0,
    }
  end

  def find_stat_by_month(facility_data, key, month)
    facility_data[key].select {|period| period == month }[month]
  end

end
