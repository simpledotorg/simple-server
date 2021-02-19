# frozen_string_literal: true

class MyFacilities::FacilityPerformanceController < AdminController
  include Pagination
  include MyFacilitiesFiltering

  layout "my_facilities"

  DEFAULT_ANALYTICS_TIME_ZONE = "Asia/Kolkata"
  PERIODS_TO_DISPLAY = {quarter: 3, month: 3, day: 14}.freeze

  after_action :verify_authorization_attempted

  around_action :set_time_zone
  before_action :authorize_my_facilities
  before_action :set_last_updated_at

  def show
    unless current_admin.feature_enabled?(:ranked_facilities)
      redirect_to my_facilities_overview_path(request.query_parameters)
      return
    end

    set_period
    @facilities = filter_facilities

    @data_for_facility = {}
    @scores_for_facility = {}

    @facilities.each do |facility|
      @data_for_facility[facility.name] = Reports::RegionService.new(region: facility,
                                                                     period: @period).call

      @scores_for_facility[facility.name] = Reports::PerformanceScore.new(region: facility,
                                                                          reports_result: @data_for_facility[facility.name],
                                                                          period: @period)
    end

    @facilities = @facilities.sort_by { |facility| @scores_for_facility[facility.name].overall_score }
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
    period_params = report_params[:period]
    @period = if period_params.present?
      Period.new(period_params)
    else
      Reports::RegionService.default_period.previous
    end
  end

  def report_params
    params.permit(:id, :force_cache, :report_scope, {period: [:type, :value]})
  end
end
