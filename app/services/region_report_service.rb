class RegionReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24
  CACHE_VERSION = 3

  def initialize(region:, period:, current_user:)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @region = region
    @period = period
    @facilities = region.facilities.to_a
    start_period = period.advance(months: -MAX_MONTHS_OF_DATA)
    @range = start_period..@period
    @data = {
      controlled_patients: {},
      registrations: {},
      cumulative_registrations: 0,
      quarterly_registrations: [],
      top_region_benchmarks: {}
    }.with_indifferent_access
  end

  attr_reader :current_user
  attr_reader :data
  attr_reader :facilities
  attr_reader :organizations
  attr_reader :period
  attr_reader :range
  attr_reader :region

  def call
    compile_control_and_registration_data
    data.merge! compile_cohort_trend_data
    data[:visited_without_bp_taken] = count_visited_without_bp_taken
    data[:visited_without_bp_taken_rate] = percentage_visited_without_bp_taken
    data[:top_region_benchmarks].merge!(top_region_benchmarks)

    data
  end

  # visited in last 3 months but had no BP taken
  def count_visited_without_bp_taken
    range.each_with_object({}) do |period, hsh|
      visits_without_bp = Appointment.from(patients_visited_without_bp_taken(period), "appointments").count("appointments.patient_id")
      hsh[period] = visits_without_bp
    end
  end

  def percentage_visited_without_bp_taken
    data[:visited_without_bp_taken].each_with_object({}) do |(period, count), hsh|
      hsh[period] = if count&.zero?
        0
      else
        percentage(count, data[:cumulative_registrations].fetch(period))
      end
    end
  end

  def percentage(numerator, denominator)
    return 0 if denominator == 0
    ((numerator.to_f / denominator) * 100).round(0)
  end

  def patients_visited_without_bp_taken(period)
    end_date = period.to_date
    begin_date = period.advance(months: -3).to_date
    Appointment.select("DISTINCT ON (appointments.patient_id) appointments.*")
      .joins(:patient)
      .joins("LEFT OUTER JOIN blood_pressures ON blood_pressures.patient_id = appointments.patient_id")
      .order("appointments.patient_id")
      .where("blood_pressures.id IS NULL")
      .where("appointments.device_created_at :: DATE BETWEEN :begin AND :end", begin: begin_date, end: end_date)
      .where("patients.registration_facility_id in (?)", facilities)
  end

  def compile_control_and_registration_data
    result = ControlRateService.new(region, periods: range).call
    @data.merge! result
  end

  # We want to return cohort data for the current quarter for the selected date, and then
  # the previous three quarters. Each quarter cohort is made up of patients registered
  # in the previous quarter who has had a follow up visit in the current quarter.
  def compile_cohort_trend_data
    Rails.cache.fetch(cohort_cache_key, version: cohort_cache_version, expires_in: 7.days, force: force_cache?) do
      result = {quarterly_registrations: []}
      period.to_quarter_period.value.downto(3).each do |results_quarter|
        cohort_quarter = results_quarter.previous_quarter

        period = {cohort_period: :quarter,
                  registration_quarter: cohort_quarter.number,
                  registration_year: cohort_quarter.year}
        query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities, cohort_period: period)
        result[:quarterly_registrations] << {
          results_in: format_quarter(results_quarter),
          patients_registered: format_quarter(cohort_quarter),
          registered: query.cohort_registrations.count,
          controlled: query.cohort_controlled_bps.count,
          no_bp: query.cohort_missed_visits_count,
          uncontrolled: query.cohort_uncontrolled_bps.count
        }.with_indifferent_access
      end
      result
    end
  end

  private

  def cohort_cache_key
    "#{self.class}/cohort_trend_data/#{region.model_name}/#{region.id}/#{organizations.map(&:id)}/#{period}/#{CACHE_VERSION}"
  end

  def cohort_cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end

  def format_quarter(quarter)
    "#{quarter.year} Q#{quarter.number}"
  end

  def top_region_benchmarks
    scope = region.class.to_s.underscore.to_sym
    TopRegionService.new(organizations, period, scope: scope).call
  end
end
