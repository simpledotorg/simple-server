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

      period = {cohort_period: :month,
                registration_month: time.month,
                registration_year: time.year}
      monthly_bps = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities, cohort_period: period)

      controlled_bps = Integer(monthly_bps.cohort_controlled_bps.count || 0)
      @data[:controlled_patients][formatted_period] = controlled_bps
      @data[:cumulative_registrations] += registrations.fetch(key, 0).to_i.round
      @data[:registrations][formatted_period] = @data[:cumulative_registrations]
    end
  end

  def compile_cohort_trend_data
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
      query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities, cohort_period: period)
      @data[:quarterly_registrations] << {
        results_in: formatted_next_quarter,
        patients_registered: formatted_current_quarter,
        registered: query.cohort_registrations.count,
        controlled: query.cohort_controlled_bps.count,
        no_bp: query.cohort_missed_visits_count,
        uncontrolled: query.cohort_uncontrolled_bps.count,
      }.with_indifferent_access
    end
  end

  def registrations
    registrations_query ||= MyFacilities::RegistrationsQuery.new(facilities: @facilities, period: :month, last_n: 12)
    registrations_query.registrations.group(:year, :month).sum(:registration_count)
  end

end