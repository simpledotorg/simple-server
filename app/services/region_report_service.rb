class RegionReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24

  def initialize(region:, selected_date:, current_user:)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @region = region
    @facilities = region.facilities
    @selected_date = selected_date.end_of_month
    @data = {
      controlled_patients: {},
      registrations: {},
      cumulative_registrations: 0,
      quarterly_registrations: [],
      top_district_benchmarks: {}
    }.with_indifferent_access
  end

  attr_reader :current_user
  attr_reader :data
  attr_reader :region
  attr_reader :facilities
  attr_reader :organizations
  attr_reader :selected_date

  def call
    compile_control_and_registration_data
    compile_cohort_trend_data
    compile_benchmarks

    data
  end

  def compile_control_and_registration_data
    start_range = selected_date.advance(months: -MAX_MONTHS_OF_DATA).to_date
    result = ControlRateService.new(region, range: (start_range..selected_date.to_date)).call
    @data.merge! result
  end

  # We want to return cohort data for the current quarter for the selected date, and then
  # the previous three quarters. Each quarter cohort is made up of patients registered
  # in the previous quarter who has had a follow up visit in the current quarter.
  def compile_cohort_trend_data
    Quarter.new(date: selected_date).downto(3).each do |results_quarter|
      cohort_quarter = results_quarter.previous_quarter

      period = {cohort_period: :quarter,
                registration_quarter: cohort_quarter.number,
                registration_year: cohort_quarter.year}
      query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities, cohort_period: period)
      @data[:quarterly_registrations] << {
        results_in: format_quarter(results_quarter),
        patients_registered: format_quarter(cohort_quarter),
        registered: query.cohort_registrations.count,
        controlled: query.cohort_controlled_bps.count,
        no_bp: query.cohort_missed_visits_count,
        uncontrolled: query.cohort_uncontrolled_bps.count
      }.with_indifferent_access
    end
  end

  def compile_benchmarks
    @data[:top_district_benchmarks].merge!(top_district_benchmarks)
  end

  def format_quarter(quarter)
    "#{quarter.year} Q#{quarter.number}"
  end

  def top_district_benchmarks
    scope = region.class.to_s.underscore.to_sym
    TopRegionService.new(organizations, selected_date, scope: scope).call
  end
end
