class ReportsController < AdminController
  layout "reports"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone
  helper_method :compute_percentage

  EXAMPLE_DATA_FILE = "db/data/example_dashboard_data.json"

  def index
    authorize :dashboard, :view_my_facilities?

    @state_name = "Punjab"
    @district_name = "Bathinda"
    @report_period = "APR-2020"
    @last_updated = "28-MAY-2020"
    # 20% Bathinda population
    @hypertensive_population = 277705

    example_data = File.read(EXAMPLE_DATA_FILE)
    data = JSON.parse(example_data)

    @controlled_patients = data["controlled_patients"]
    @registrations = data["registrations"]
    @quarterly_registrations = data["quarterly_registrations"]
  end

  private

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end

  def compute_percentage numerator, denominator
    quotient = numerator.to_f / denominator.to_f
    quotient * 100
  end
end
