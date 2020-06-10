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
    @data = {
      controlled_patients: {},
      registrations: {},
      cumulative_registrations: 0
    }.with_indifferent_access
    -11.upto(0).each do |n|
      time = selected_date.advance(months: n)
      formatted_period = time.strftime("%b %Y")
      key = [@facility.id, time.year.to_s, time.month.to_s]

      period = {cohort_period: :month,
                registration_month: time.month,
                registration_year: time.year}
      monthly_bps = MyFacilities::BloodPressureControlQuery.new(facilities: [@facility], cohort_period: period)

      controlled_bps = Integer(monthly_bps.cohort_controlled_bps.group(:registration_facility_id).count[@facility.id] || 0)
      @data[:controlled_patients][formatted_period] = controlled_bps
      @data[:cumulative_registrations] += registrations.fetch(key, 0).to_i.round
      @data[:registrations][formatted_period] = @data[:cumulative_registrations]
    end

    -1.downto(-4).each do |quarter|
      date = selected_date.advance(months: quarter * 3)
      quarter = QuarterHelper.quarter(date)
      year = date.year
      next_quarter = QuarterHelper.next_year_and_quarter(year, quarter)
      formatted_current_quarter = "Q#{quarter}-#{year}"
      formatted_next_quarter = "Q#{next_quarter[1]}-#{next_quarter[0]}"

      period = {cohort_period: :quarter,
                registration_quarter: quarter,
                registration_year: year}
      query = MyFacilities::BloodPressureControlQuery.new(facilities: [@facility], cohort_period: period)
      @data[:quarterly_registrations] ||= []
      @data[:quarterly_registrations] << {
        results_in: formatted_next_quarter,
        patients_registered: formatted_current_quarter,
        cohort_trend: [
          {
            period: formatted_current_quarter,
            registered: query.cohort_registrations.count,
            controlled: {
              total: query.cohort_controlled_bps.count,
              percent: 22,
            },
            no_bp: {
              total: query.cohort_missed_visits_count,
              percent: 22,
            },
            uncontrolled: {
              total: query.cohort_uncontrolled_bps.count,
              percent: 22,
            }
          }.with_indifferent_access
        ]
      }.with_indifferent_access
    end

    if report_params[:source] == "live"
      @controlled_patients = @data["controlled_patients"]
      @control_rate = example_data["control_rate"]
      @registrations = @data["registrations"]
      @quarterly_registrations = @data[:quarterly_registrations]
      pp @data[:quarterly_registrations].to_json

      p "registrations"
      pp @registrations.map { |key, val| [key, val.to_s.rjust(3)] }
      pp @controlled_patients

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

  def controlled_bps
    period = {cohort_period: :month, registration_month: 6, registration_quarter: 1, registration_year: 2020}
    bp_query = MyFacilities::BloodPressureControlQuery.new(facilities: [@facility],
                                                           cohort_period: period)
    @controlled_bps ||= bp_query.cohort_controlled_bps.group(:registration_facility_id).count
  end

  def registrations
    registrations_query = MyFacilities::RegistrationsQuery.new(facilities:
      @facility, period: :month, last_n: 12)
    @result ||= registrations_query.registrations.group(:facility_id, :year, :month).sum(:registration_count)
    @result
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end
end
