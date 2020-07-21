class Reports::RegionsController < AdminController
  layout "application"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  def index
    authorize(:dashboard, :show?)

    @organizations = policy_scope([:cohort_report, Organization]).order(:name)
  end

  def cohort
    @region = report_scope.find_by!(slug: facility_params[:id])
    authorize(:dashboard, :show?)
    RequestStore.store[:force_cache] = true if force_cache?

    @selected_date = if facility_params[:selected_date]
      Time.parse(facility_params[:selected_date])
    else
      Date.current.advance(months: -1)
    end
    @data = RegionReportService.new(region: @region,
                                    selected_date: @selected_date,
                                    current_user: current_admin).cohort_data
    # @controlled_patients = @data[:controlled_patients]
    # @registrations = @data[:registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    # @top_region_benchmarks = @data[:top_region_benchmarks]
    # @last_registration_value = @data[:registrations].values&.last || 0
  end

  def show
    @region = report_scope.find_by!(slug: facility_params[:id])
    authorize(:dashboard, :show?)
    RequestStore.store[:force_cache] = true if force_cache?

    @selected_date = if facility_params[:selected_date]
      Time.parse(facility_params[:selected_date])
    else
      Date.current.advance(months: -1)
    end
    @data = RegionReportService.new(region: @region,
                                    selected_date: @selected_date,
                                    current_user: current_admin).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @top_region_benchmarks = @data[:top_region_benchmarks]
    @last_registration_value = @data[:registrations].values&.last || 0
  end

  private

  def report_scope
    @report_scope ||= case facility_params[:report_scope]
    when "facility_group"
      then FacilityGroup
    when "facility"
      then Facility
    else
      raise ArgumentError, "unknown report_scope #{facility_params[:report_scope]}"
    end
  end

  def facility_params
    params.permit(:selected_date, :id, :force_cache, :report_scope)
  end

  def force_cache?
    facility_params[:force_cache].present?
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) { yield }
    Groupdate.time_zone = "UTC"
  end
end
