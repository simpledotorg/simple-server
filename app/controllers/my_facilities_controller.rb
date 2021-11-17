# frozen_string_literal: true

class MyFacilitiesController < AdminController
  include Pagination
  include MyFacilitiesFiltering
  include CohortPeriodSelection
  include PeriodSelection

  PERIODS_TO_DISPLAY = {quarter: 3, month: 3, day: 14}.freeze

  around_action :set_reporting_time_zone
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
    process_facility_stats(:controlled_patients)
  end

  def bp_not_controlled
    process_facility_stats(:uncontrolled_patients)
  end

  def missed_visits
    process_facility_stats(:missed_visits)
  end

  def csv_maker
    facilities = filter_facilities
    service = BloodPressureExportService.new(start_period: @start_period, end_period: @period, facilities: facilities)
    csv_data = service.as_csv
    filename = "Blood Pressure Data #{@selected_facility_group.name}.csv"
    send_data csv_data, type: "text/csv", filename: filename
  end

  private

  def set_last_updated_at
    last_updated_at = RefreshReportingViews.last_updated_at
    @last_updated_at =
      if last_updated_at.nil?
        "unknown"
      else
        last_updated_at.in_time_zone(Rails.application.config.country[:time_zone]).strftime("%d-%^b-%Y %I:%M%p")
      end
  end

  def authorize_my_facilities
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def set_period
    @period = Period.month(Date.current.last_month.beginning_of_month)
    @start_period = @period.advance(months: -5)
  end

  def report_params
    params.permit(:id, :bust_cache, :report_scope, {period: [:type, :value]})
  end

  def process_facility_stats(type)
    facilities = filter_facilities
    sizes = facilities.pluck(:facility_size).uniq

    presenter = Reports::RepositoryPresenter.create(facilities, period: @period, months: 6)
    @data_for_facility = facilities.each_with_object({}) do |facility, result|
      result[facility.name] = presenter.my_facilities_hash(facility.region)
    end
    @display_sizes = @facility_sizes.select { |size| sizes.include?(size) }
    @stats_by_size = FacilityStatsService.call(facilities: @data_for_facility, period: @period)
  end
end
