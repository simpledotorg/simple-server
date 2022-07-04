class MonthlyDistrictReport::Diabetes::BlockData
  include MonthlyDistrictReport::Utils
  attr_reader :repo, :district, :report_month, :last_6_months

  def initialize(district, period_month)
    @district = district
    @report_month = period_month
    @last_6_months = Range.new(@report_month.advance(months: -5), @report_month)
    @repo = Reports::Repository.new(district.block_regions, periods: @last_6_months)
  end

  def content_rows
    district
      .block_regions
      .order(:name)
      .map do |block|
      row_data(block)
    end
  end

  def header_rows
    [[ # row 1
      "Blocks",
      "Total diabetes registrations",
      "Total assigned diabetes patients",
      "Total diabetes patients under care",
      "Total diabetes patients lost to followup",
      "Treatment outcome", *Array.new(4, nil),
      "Total registered diabetes patients", *Array.new(5, nil),
      "Diabetes patients under care", *Array.new(5, nil),
      "New registered diabetes patients", *Array.new(5, nil),
      "Diabetes patient follow-ups", *Array.new(5, nil),
      "Blood sugar below 200 rate", *Array.new(5, nil),
      "Blood sugar 200 to 300 rate", *Array.new(5, nil),
      "Blood sugar over 300 rate", *Array.new(5, nil)
    ],
      [ # row 2
        nil, # "Blocks"
        nil, # "Total registrations"
        nil, # "Total assigned patients"
        nil, # "Total patients under care"
        nil, # "Total patients lost to followup"
        "% Blood Sugar Below 200",
        "% Blood Sugar between 200 and 300",
        "% Blood Sugar Over 300",
        "% Missed Visits",
        "% Visits, no blood sugar taken",
        *last_6_months.map { |period| format_period(period) }, # "Total registered patients"
        *last_6_months.map { |period| format_period(period) }, # "Patients under care"
        *last_6_months.map { |period| format_period(period) }, # "New registered patients"
        *last_6_months.map { |period| format_period(period) }, # "Patient follow-ups"
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar below 200 rate",
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar 200 to 300 rate",
        *last_6_months.map { |period| format_period(period) } # "Blood sugar over 300 rate",
      ]]
  end

  private

  def row_data(block)
    {
      "Blocks" => block.name,
      "Total diabetes registrations" => repo.cumulative_diabetes_registrations[block.slug][report_month],
      "Total assigned diabetes patients" => repo.cumulative_assigned_diabetic_patients[block.slug][report_month],
      "Total diabetes patients under care" => repo.diabetes_under_care[block.slug][report_month],
      "Total diabetes patients lost to followup" => repo.diabetes_ltfu[block.slug][report_month],
      "% Blood Sugar Below 200" => percentage_string(repo.bs_below_200_rates[block.slug][report_month]), # "% BS <200",
      "% Blood Sugar between 200 and 300" => percentage_string(repo.bs_200_to_300_rates[block.slug][report_month]), # "% 200 <= BS < 300",
      "% Blood Sugar Over 300" => percentage_string(repo.bs_over_300_rates[block.slug][report_month]), # "% BS >=300",
      "% Missed Visits" => percentage_string(repo.diabetes_missed_visits_rates[block.slug][report_month]), # "% Missed Visits",
      "% Visits, no blood sugar taken" => percentage_string(repo.visited_without_bs_taken_rates[block.slug][report_month]), # "% Visits, no Blood sugar taken",
      **last_6_months_data(repo.cumulative_registrations, block, :cumulative_diabetes_registrations),
      **last_6_months_data(repo.under_care, block, :diabetes_under_care),
      **last_6_months_data(repo.monthly_registrations, block, :monthly_diabetes_registrations),
      **last_6_months_data(repo.hypertension_follow_ups, block, :diabetes_follow_ups),
      **last_6_months_data(repo.bs_below_200_rates, block, :bs_below_200_rates, true),
      **last_6_months_data(repo.bs_200_to_300_rates, block, :bs_200_to_300_rates, true),
      **last_6_months_data(repo.bs_over_300_rates, block, :bs_over_300_rates, true)
    }
  end

  def last_6_months_data(data, block, indicator, show_as_rate = false)
    last_6_months.each_with_object({}) do |month, hsh|
      value = data.dig(block.slug, month)
      hsh["#{indicator} - #{month}"] = indicator_string(value, show_as_rate)
    end
  end
end
