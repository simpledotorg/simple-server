class ReportsController < AdminController
  layout "reports"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  EXAMPLE_DATA_FILE = "db/data/example_dashboard_data.json"
  PERIODS_TO_DISPLAY = 12

  def index
    authorize :dashboard, :view_my_facilities?

    @facility_groups = policy_scope([:manage, FacilityGroup]).order(:name)
    @facility = Facility.find_by(name: "CHC Barnagar")

    @state_name = "Punjab"
    @district_name = "Bathinda"
    @report_period = "APR-2020"
    @last_updated = "28-MAY-2020"
    # 20% Bathinda population
    @hypertensive_population = 277705

    example_data_file = File.read(EXAMPLE_DATA_FILE)
    example_data = JSON.parse(example_data_file)

    selected_date = Date.current
    service = DistrictReportService.new(facilities: @facility, selected_date: selected_date)
    @data = service.call

    if report_params[:source] == "live"
      @controlled_patients = @data["controlled_patients"]
      @control_rate = example_data["control_rate"]
      @registrations = @data["registrations"]
      @quarterly_registrations = @data[:quarterly_registrations]
    else
      @controlled_patients = example_data["controlled_patients"]
      @control_rate = example_data["control_rate"]
      @registrations = example_data["registrations"]
      @quarterly_registrations = example_data["quarterly_registrations"]
    end
  end

  private

  def report_params
    params.permit(:source)
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end
end
