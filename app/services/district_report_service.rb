class DistrictReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24

  def initialize(district: nil, selected_date:)
    @district = district
    @facilities = district.facilities
    @selected_date = selected_date
    @data = {
      controlled_patients: {},
      registrations: {},
      cumulative_registrations: 0,
      quarterly_registrations: [],
      top_district_benchmarks: {}
    }.with_indifferent_access
  end

  attr_reader :district, :selected_date, :facilities, :data

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

  def percentage(numerator, denominator)
    return 0 if denominator == 0
    (numerator.to_f / denominator) * 100
  end

  def compile_benchmarks
    @data[:top_district_benchmarks].merge!(top_district_benchmarks)
  end

  def format_quarter(quarter)
    "Q#{quarter.number}-#{quarter.year}"
  end

  def lookup_registration_count(date)
    lookup_date = date.beginning_of_month.to_date
    registration_counts[lookup_date]
  end

  def registration_counts
    @registration_counts ||= district.patients.with_hypertension
      .group_by_period(:month, :recorded_at, range: MAX_MONTHS_OF_DATA.months.ago..selected_date)
      .count
      .each_with_object(Hash.new(0)) { |(date, count), hsh|
        hsh[:running_total] += count
        hsh[date] = hsh[:running_total]
      }.delete_if { |date, count| count == 0 }.except(:running_total)
  end

  def controlled_patients_count(time)
    ControlledPatientsQuery.call(facilities: facilities, time: time).count
  end

  def percentage(numerator, denominator)
    return 0 if denominator == 0
    (numerator.to_f / denominator) * 100
  end

  def top_district_benchmarks
    districts_by_rate = FacilityGroup.all.each_with_object({}) { |district, hsh|
      controlled = ControlledPatientsQuery.call(facilities: district.facilities, time: selected_date).count
      registration_count = Patient.with_hypertension.where(registration_facility: district.facilities).where("recorded_at <= ?", selected_date).count
      hsh[district] = percentage(controlled, registration_count)
    }
    district, percentage = districts_by_rate.max_by { |district, rate| rate }
    {
      district: district,
      controlled_percentage: percentage
    }
  end
end
