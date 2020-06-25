class Dashboard::DistrictsController < AdminController
  layout "application"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  EXAMPLE_DATA_FILE = "db/data/example_dashboard_data.json"

  def index
    authorize([:manage, Organization])
    @organizations = policy_scope([:manage, Organization]).order(:name)
  end

  def show
    @district = FacilityGroup.find_by(slug: params[:id])
    authorize([:manage, @district])

    @district_name = @district.name

    @report_period = Date.current.advance(months: -1)

    @data = DistrictReportService.new(facilities: @district.facilities, selected_date: @report_period).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
  end

  private

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end
end
