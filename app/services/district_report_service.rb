class DistrictReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24

  def initialize(facilities:, selected_date:, current_user:)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @facilities = Array(facilities)
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
    months_of_data = [registration_counts.to_a.size, MAX_MONTHS_OF_DATA].min
    @data[:cumulative_registrations] = lookup_registration_count(selected_date)
    (-months_of_data + 1).upto(0).each do |n|
      time = selected_date.advance(months: n).end_of_month
      formatted_period = time.to_s(:month_year)

      @data[:controlled_patients][formatted_period] = controlled_patients_count(time)
      @data[:registrations][formatted_period] = lookup_registration_count(time)
    end
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

  def lookup_registration_count(date)
    lookup_date = date.beginning_of_month.to_date.to_s
    row = registration_counts.find { |r| r["date"] == lookup_date }
    return 0 unless row
    row["running_ct"].to_i
  end

  def registration_counts
    where_clause = ActiveRecord::Base.sanitize_sql_array([
      "registration_facility_id in (?) and medical_histories.hypertension = ?",
      @facilities, "yes"
    ])

    @registration_counts ||= Patient.connection.select_all(<<-SQL)
      WITH cte AS (
        SELECT date_trunc('month', "recorded_at") AS month, count(*) AS month_ct
        FROM   patients
        INNER JOIN medical_histories on patients.id = medical_histories.patient_id
        WHERE #{where_clause}
        GROUP  BY 1)
      SELECT date(m.month), COALESCE(sum(cte.month_ct) OVER (ORDER BY m.month), 0) AS running_ct
      FROM  (
          SELECT generate_series(min(month), '#{selected_date}'::timestamp, interval '1 month')
          FROM   cte
          ) m(month)
      LEFT JOIN cte USING (month)
      ORDER BY 1;
    SQL
  end

  def controlled_patients_count(time)
    ControlledPatientsQuery.call(facilities: facilities, time: time).count
  end

  def top_district_benchmarks
    TopDistrictService.new(organizations, selected_date).call
  end
end
