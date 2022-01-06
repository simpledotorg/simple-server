# frozen_string_literal: true

module MonthlyDistrictReport
  class BlockData
    include Utils
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
        "Total registrations",
        "Total assigned patients",
        "Total patients under care",
        "Total patients lost to followup",
        "Treatment outcome", *Array.new(3, nil),
        "Total registered patients", *Array.new(5, nil),
        "Patients under care", *Array.new(5, nil),
        "New registered patients", *Array.new(5, nil),
        "Patient follow-ups", *Array.new(5, nil),
        "BP controlled rate", *Array.new(5, nil)
      ],
        [ # row 2
          nil, # "Blocks"
          nil, # "Total registrations"
          nil, # "Total assigned patients"
          nil, # "Total patients under care"
          nil, # "Total patients lost to followup"
          "% BP controlled",
          "% BP uncontrolled",
          "% Missed Visits",
          "% Visits, no BP taken",
          *last_6_months.map { |period| format_period(period) }, # "Total registered patients"
          *last_6_months.map { |period| format_period(period) }, # "Patients under care"
          *last_6_months.map { |period| format_period(period) }, # "New registered patients"
          *last_6_months.map { |period| format_period(period) }, # "Patient follow-ups"
          *last_6_months.map { |period| format_period(period) } # "BP controlled rate"
        ]]
    end

    private

    def row_data(block)
      {
        "Blocks" => block.name,
        "Total registrations" => repo.cumulative_registrations[block.slug][report_month],
        "Total assigned patients" => repo.cumulative_assigned_patients[block.slug][report_month],
        "Total patients under care" => repo.under_care[block.slug][report_month],
        "Total patients lost to followup" => repo.ltfu[block.slug][report_month],
        "% BP controlled" => percentage_string(repo.controlled_rates[block.slug][report_month]),
        "% BP uncontrolled" => percentage_string(repo.uncontrolled_rates[block.slug][report_month]),
        "% Missed Visits" => percentage_string(repo.missed_visits_rate[block.slug][report_month]),
        "% Visits, no BP taken" => percentage_string(repo.visited_without_bp_taken_rates[block.slug][report_month]),
        **last_6_months_data(repo.cumulative_registrations, block, :cumulative_registrations),
        **last_6_months_data(repo.under_care, block, :under_care),
        **last_6_months_data(repo.monthly_registrations, block, :monthly_registrations),
        **last_6_months_data(repo.hypertension_follow_ups, block, :hypertension_follow_ups),
        **last_6_months_data(repo.controlled_rates, block, :controlled_rates, true)
      }
    end

    def last_6_months_data(data, block, indicator, show_as_rate = false)
      last_6_months.each_with_object({}) do |month, hsh|
        value = data.dig(block.slug, month)
        hsh["#{indicator} - #{month}"] = indicator_string(value, show_as_rate)
      end
    end
  end
end
