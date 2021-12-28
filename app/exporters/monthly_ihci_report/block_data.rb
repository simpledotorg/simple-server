module MonthlyIHCIReport
  class BlockData
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
          *last_6_months.map(&:to_s), # "Total registered patients"
          *last_6_months.map(&:to_s), # "Patients under care"
          *last_6_months.map(&:to_s), # "New registered patients"
          *last_6_months.map(&:to_s), # "Patient follow-ups"
          *last_6_months.map(&:to_s) # "BP controlled rate"
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
        "% BP controlled" => repo.controlled_rates[block.slug][report_month],
        "% BP uncontrolled" => repo.uncontrolled_rates[block.slug][report_month],
        "% Missed Visits" => repo.missed_visits_rate[block.slug][report_month],
        "% Visits, no BP taken" => repo.visited_without_bp_taken_rates[block.slug][report_month],
        "Total registered patients" => last_6_months_data(repo.cumulative_registrations, block),
        "Patients under care" => last_6_months_data(repo.under_care, block),
        "New registered patients" => last_6_months_data(repo.monthly_registrations, block),
        "Patient follow-ups" => last_6_months_data(repo.hypertension_follow_ups, block),
        "BP controlled rate" => last_6_months_data(repo.controlled_rates, block)
      }
    end

    def last_6_months_data(data, block)
      last_6_months.each_with_object({}) do |month, hsh|
        hsh[month.to_s] = data[block.slug][month]
      end
    end
  end
end
