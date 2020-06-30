class Dashboard::DistrictsController < AdminController
  layout "application"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  def index
    authorize([:manage, Organization])
    @organizations = policy_scope([:manage, :facility, Organization])
  end

  def show
    @district = FacilityGroup.find_by(slug: district_params[:id])
    authorize([:manage, @district])

    @selected_date = if district_params[:selected_date]
      Time.parse(district_params[:selected_date])
    else
      Date.current.advance(months: -1)
    end
    @data = DistrictReportService.new(district: @district, selected_date: @selected_date).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @top_district_benchmarks = @data[:top_district_benchmarks]
  end

  private

  def district_params
    params.permit(:selected_date, :id)
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) { yield }
    Groupdate.time_zone = "UTC"
  end
end
