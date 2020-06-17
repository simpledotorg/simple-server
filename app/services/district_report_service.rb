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
    -11.upto(0).each do |n|
      time = selected_date.advance(months: n)
      formatted_period = time.strftime("%b %Y")
      key = [time.year.to_s, time.month.to_s]

      @data[:controlled_patients][formatted_period] = controlled_patients(time).count
      @data[:cumulative_registrations] += registrations.fetch(key, 0).to_i.round
      @data[:registrations][formatted_period] = @data[:cumulative_registrations]
    end
  end

  def compile_cohort_trend_data
    -1.downto(-4).each do |quarter|
      date = selected_date.advance(months: quarter * 3)
      quarter = QuarterHelper.quarter(date)
      year = date.year
      next_year, next_quarter = QuarterHelper.next_year_and_quarter(year, quarter)
      formatted_current_quarter = "Q#{quarter}-#{year}"
      formatted_next_quarter = "Q#{next_quarter}-#{next_year}"

      period = {cohort_period: :quarter,
                registration_quarter: quarter,
                registration_year: year}
      query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities, cohort_period: period)
      @data[:quarterly_registrations] << {
        results_in: formatted_next_quarter,
        patients_registered: formatted_current_quarter,
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

  def registrations
    registrations_query ||= MyFacilities::RegistrationsQuery.new(facilities: @facilities, period: :month, last_n: 12)
    registrations_query.registrations.group(:year, :month).sum(:registration_count)
  end


end
