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
    @facilities = filter_facilities

    @data_for_facility = {}

    @facilities.each do |facility|
      @data_for_facility[facility.name] = Reports::RegionService.new(region: facility, period: @period).call
    end

    @facilities_by_size = @facilities.group_by { |facility| facility.facility_size }

    monthly_stats
  end

  private def monthly_stats
    sizes = @facilities_by_size.keys
    @period_stats = {}
    sizes.each do |size|
      @period_stats[size] = {}
      relevant_periods.each do |current_period|
        period_key = current_period.to_s
        @period_stats[size][period_key] = {
          'controlled_patients' => 0,
          'adjusted_registrations' => 0,
          'cumulative_registrations' => 0,
        }
        @facilities_by_size[size].each do |facility|
          facility_data = @data_for_facility[facility.name]
          @period_stats[size][period_key]['controlled_patients'] += facility_data.controlled_patients.select {|month| month.value == current_period.value }[current_period]
          @period_stats[size][period_key]['adjusted_registrations'] += facility_data.adjusted_registrations.select {|month| month.value == current_period.value }[current_period]
          @period_stats[size][period_key]['cumulative_registrations'] += facility_data.cumulative_registrations.select {|month| month.value == current_period.value }[current_period]
        end
      end

      cumulative_controlled = @period_stats[size].map{|_, aggregates| aggregates['controlled_patients'] }.sum
      cumulative_adjusted = @period_stats[size].map{|_, aggregates| aggregates['adjusted_registrations'] }.sum
      @period_stats[size]['control_rate'] = (cumulative_controlled.to_f / cumulative_adjusted.to_f * 100).round
    end
  end

  private def relevant_periods
    @relevant_periods ||= @period.downto(5)
  end

  def bp_not_controlled
    @facilities = filter_facilities

    @data_for_facility = {}

    @facilities.each do |facility|
      @data_for_facility[facility.name] = Reports::RegionService.new(region: facility, period: @period).call
    end

    @facilities_by_size = @facilities.group_by { |facility| facility.facility_size }
  end

  def missed_visits
    @facilities = filter_facilities

    @data_for_facility = {}

    @facilities.each do |facility|
      @data_for_facility[facility.name] = Reports::RegionService.new(region: facility, period: @period).call
    end

    @facilities_by_size = @facilities.group_by { |facility| facility.facility_size }
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
end
