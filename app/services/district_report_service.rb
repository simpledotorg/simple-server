class DistrictReportService
  def initialize(facilities:, selected_date:)
    @facilities = Array(facilities)
    @selected_date = selected_date
    @data = {
      controlled_patients: {},
      registrations: {},
      cumulative_registrations: 0,
      quarterly_registrations: []
    }.with_indifferent_access
  end

  attr_reader :selected_date, :facilities, :data

  def call
    compile_control_and_registration_data

    compile_cohort_trend_data

    data
  end

  def compile_control_and_registration_data
    @data[:cumulative_registrations] = Patient.where(registration_facility: @facilities).
      with_hypertension.where("recorded_at <= ?", selected_date.end_of_month).count
    -11.upto(0).each do |n|
      time = selected_date.advance(months: n).end_of_month
      formatted_period = time.to_s(:month_year)

      count = Patient.where(registration_facility: @facilities).where("recorded_at <= ?", time).count

      @data[:controlled_patients][formatted_period] = controlled_patients(time).count
      @data[:registrations][formatted_period] = count
    end
  end

  def format_quarter(quarter)
    "Q#{quarter.number}-#{quarter.year}"
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

  def controlled_patients(time)
    end_range = time.end_of_month
    mid_range = time.advance(months: -1).end_of_month
    beg_range = time.advance(months: -2).end_of_month
    sub_query = LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id) *")
      .under_control
      .order("patient_id, bp_recorded_at DESC, bp_id")
      .where(registration_facility_id: facilities)
      .where("(year = ? AND month = ?) OR (year = ? AND month = ?) OR (year = ? AND month = ?)",
        beg_range.year.to_s, beg_range.month.to_s,
        mid_range.year.to_s, mid_range.month.to_s,
        end_range.year.to_s, end_range.month.to_s)
    LatestBloodPressuresPerPatientPerMonth.from(sub_query, "latest_blood_pressures_per_patient_per_months")
  end
end
