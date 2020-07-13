class Reports::RegionsController < AdminController
  layout "application"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  def index
    authorize(:dashboard, :show?)

    @organizations = policy_scope([:cohort_report, Organization]).order(:name)
  end

  def show
    @region = scope.find_by!(slug: facility_params[:id])
    authorize(:dashboard, :show?)
    force_cache = true if facility_params[:force_cache].present?

    @selected_date = if facility_params[:selected_date]
      Time.parse(facility_params[:selected_date])
    else
      Date.current.advance(months: -1)
    end
    @data = RegionReportService.new(region: @region,
                                    selected_date: @selected_date,
                                    current_user: current_admin,
                                    force_cache: force_cache).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @top_district_benchmarks = @data[:top_district_benchmarks]
    @last_registration_value = @data[:registrations].values&.last || 0
  end

  private

  def scope
    case scope = facility_params[:scope]
    when "facility_group"
      then FacilityGroup
    when "facility"
      then Facility
    else
      raise ArgumentError, "unknown scope #{scope}"
    end
  end

  def facility_params
    params.permit(:selected_date, :id, :force_cache, :scope)
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) { yield }
    Groupdate.time_zone = "UTC"
  end
end
