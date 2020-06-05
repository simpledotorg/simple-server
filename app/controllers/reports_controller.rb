class ReportsController < AdminController
  layout "reports"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  EXAMPLE_DATA_FILE = "db/data/example_dashboard_data.json"

  def index
    authorize :dashboard, :view_my_facilities?

    @state_name = "Punjab"
    @district_name = "Bathinda"
    @report_period = "APR-2020"
    @last_updated = "28-MAY-2020"
    # 20% Bathinda population
    @hypertensive_population = 277705

    example_data_file = File.read(EXAMPLE_DATA_FILE)
    example_data = JSON.parse(example_data_file)

    today = Time.current
    @data = {
      controlled_patients: {}
    }.with_indifferent_access
    (0..11).each { |n|
      time = today.prev_month(n)
      formatted_period = time.strftime("%b %Y")
      @data[:controlled_patients][formatted_period] = BloodPressureRollup.controlled_in_month(time)["count"]
    }

    today.month
    @controlled_patients = @data["controlled_patients"]
    @control_rate = example_data["control_rate"]
    @registrations = example_data["registrations"]
    @quarterly_registrations = example_data["quarterly_registrations"]
  end

  private

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end
end
